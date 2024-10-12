data "node-lambda-packager_package" "handlers" {
  for_each = local.http_handlers

  args = [
    "--bundle",
    "--external:@aws-sdk*",
    "--platform=node",
    "--target=es2021",
    "--outdir=dist",
  ]

  entrypoint        = "${path.root}/${each.value.source}"
  working_directory = "${path.root}/${dirname(each.value.source)}"
}

resource "aws_lambda_function" "handlers" {
  for_each         = local.http_handlers
  filename         = data.node-lambda-packager_package.handlers[each.key].filename
  function_name    = "${var.api_name}-${each.value.name}"
  source_code_hash = data.node-lambda-packager_package.handlers[each.key].source_code_hash
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"

  environment {
    variables = each.value.environment_vars
  }

  vpc_config {
    subnet_ids         = try(var.vpc.subnet_ids, [])
    security_group_ids = try(var.vpc.security_group_ids, [])
  }

  tags = merge(each.value.tags)

  depends_on = [ 
    aws_iam_role_policy_attachment.lambda_logs,
    aws_iam_role_policy_attachment.vpc_execution_role,
  ]
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api_gateway.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_route" "lambda_routes" {
  for_each = merge([
    for handler_name, handler in local.http_handlers : {
      for method, path in handler.http : "${handler_name}_${method}" => {
        handler_name = handler_name
        method       = upper(method)
        path         = path
      }
    }
  ]...)

  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "${each.value.method} ${each.value.path}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integrations[each.value.handler_name].id}"
}

resource "aws_apigatewayv2_integration" "lambda_integrations" {
  for_each = local.http_handlers

  api_id             = aws_apigatewayv2_api.api_gateway.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.handlers[each.key].invoke_arn
}

resource "aws_apigatewayv2_api" "api_gateway" {
  name          = var.api_name
  protocol_type = "HTTP"
  tags          = try(var.http_api.tags, null)
}
