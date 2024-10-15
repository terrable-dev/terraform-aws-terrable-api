# data "node-lambda-packager_package" "handlers" {
#   for_each = local.rest_handlers

#   args = [
#     "--bundle",
#     "--external:@aws-sdk*",
#     "--platform=node",
#     "--target=es2021",
#     "--outdir=dist",
#   ]

#   entrypoint        = "${path.root}/${each.value.source}"
#   working_directory = "${path.root}/${dirname(each.value.source)}"
# }

# resource "aws_lambda_function" "handlers" {
#   for_each         = local.rest_handlers
#   filename         = data.node-lambda-packager_package.handlers[each.key].filename
#   function_name    = "${var.api_name}-${each.value.name}"
#   source_code_hash = data.node-lambda-packager_package.handlers[each.key].source_code_hash
#   role             = aws_iam_role.lambda_role[0].arn
#   handler          = "index.handler"
#   runtime          = "nodejs20.x"

#   environment {
#     variables = each.value.environment_vars
#   }

#   vpc_config {
#     subnet_ids         = try(var.vpc.subnet_ids, [])
#     security_group_ids = try(var.vpc.security_group_ids, [])
#   }

#   tags = merge(each.value.tags)

#   depends_on = [
#     aws_iam_role_policy_attachment.lambda_logs,
#     aws_iam_role_policy_attachment.vpc_execution_role,
#   ]
# }

resource "aws_api_gateway_rest_api" "api_gateway" {
  count = local.api_gateway_version == "v1" ? 1 : 0
  name  = var.api_name
  tags  = try(var.rest_api.tags, null)
}

# resource "aws_api_gateway_resource" "lambda_resources" {
#   for_each = local.rest_handlers

#   rest_api_id = aws_api_gateway_rest_api.api_gateway[0].id
#   parent_id   = aws_api_gateway_rest_api.api_gateway[0].root_resource_id
#   path_part   = each.value.http.path
# }

# resource "aws_api_gateway_method" "lambda_methods" {
#   for_each = merge([
#     for handler_name, handler in local.rest_handlers : {
#       for method, path in handler.http : "${handler_name}_${method}" => {
#         handler_name = handler_name
#         method       = upper(method)
#         path         = path
#       }
#     }
#   ]...)

#   rest_api_id   = aws_api_gateway_rest_api.api_gateway[0].id
#   resource_id   = aws_api_gateway_resource.lambda_resources[each.value.handler_name].id
#   http_method   = each.value.method
#   authorization = "NONE"
# }

# resource "aws_api_gateway_integration" "lambda_integrations" {
#   for_each = merge([
#     for handler_name, handler in local.rest_handlers : {
#       for method, path in handler.http : "${handler_name}_${method}" => {
#         handler_name = handler_name
#         method       = upper(method)
#         path         = path
#       }
#     }
#   ]...)

#   rest_api_id             = aws_api_gateway_rest_api.api_gateway[0].id
#   resource_id             = aws_api_gateway_resource.lambda_resources[each.value.handler_name].id
#   http_method             = each.value.method
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = aws_lambda_function.handlers[each.value.handler_name].invoke_arn
# }

# resource "aws_api_gateway_deployment" "api_deployment" {
#   count = local.api_gateway_version == "v1" ? 1 : 0

#   rest_api_id = aws_api_gateway_rest_api.api_gateway[0].id
#   stage_name  = "prod"

#   depends_on = [
#     aws_api_gateway_integration.lambda_integrations
#   ]
# }
