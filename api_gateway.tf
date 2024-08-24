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
  for_each = local.http_handlers
  filename = data.node-lambda-packager_package.handlers[each.key].filename
  function_name = "${var.api_name}-${each.value.name}"
  source_code_hash = data.node-lambda-packager_package.handlers[each.key].source_code_hash
  role          = aws_iam_role.lambda_role.arn
  handler = "index.handler"
  runtime = "nodejs20.x"
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.api_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api_gateway.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_route" "lambda_routes" {
  for_each = local.http_handlers

  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "${each.value.http.method} ${each.value.http.path}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integrations[each.key].id}"
}

resource "aws_apigatewayv2_integration" "lambda_integrations" {
  for_each = local.http_handlers

  api_id = aws_apigatewayv2_api.api_gateway.id
  integration_type = "AWS_PROXY"
  integration_method = "POST"
  integration_uri = aws_lambda_function.handlers[each.key].invoke_arn
}

resource "aws_apigatewayv2_api" "api_gateway" {
  name = var.api_name
  protocol_type = "HTTP"
}

resource "aws_lambda_permission" "lambda_api_gateway_execution_permission" {
  for_each = var.handlers

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.handlers[each.key].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api_gateway.execution_arn}/*/*"
}

resource "aws_cloudwatch_log_group" "lambda_log_groups" {
  for_each = local.handlers

  name              = "/aws/lambda/${aws_lambda_function.handlers[each.key].function_name}"
  retention_in_days = 1
}
