locals {
  sanitised_http_handlers = {
    for k, v in local.rest_handlers : k => {
      source = v.source
      http = {
        for method, path in v.http : method => path
      }
    }
  }

  cors_config = try(var.rest_api.cors, null) != null ? {
    allow_origins     = var.rest_api.cors.allow_origins
    allow_methods     = var.rest_api.cors.allow_methods
    allow_headers     = var.rest_api.cors.allow_headers
    expose_headers    = var.rest_api.cors.expose_headers
    max_age           = var.rest_api.cors.max_age
    allow_credentials = var.rest_api.cors.allow_credentials
  } : null

  cors_resources = local.cors_config != null ? merge(
    { "/" = aws_api_gateway_rest_api.api_gateway[0].root_resource_id },
    {
      for k, v in aws_api_gateway_resource.lambda_resources : v.path_part => v.id
    }
  ) : {}
}

resource "aws_api_gateway_rest_api" "api_gateway" {
  count = local.api_gateway_version == "v1" ? 1 : 0
  name  = var.api_name
  tags  = try(var.rest_api.tags, null)

  endpoint_configuration {
    types            = [var.rest_api.endpoint_type]
    vpc_endpoint_ids = try(var.rest_api.vpc_endpoint_ids, null)
  }
}

resource "aws_api_gateway_resource" "lambda_resources" {
  for_each = merge([
    for handler_name, handler in local.sanitised_http_handlers : {
      for method, path in handler.http : "${handler_name}_${method}" => {
        handler_name = handler_name
        method       = upper(method)
        path         = path
      }
      if path != "/"
    }
  ]...)

  rest_api_id = aws_api_gateway_rest_api.api_gateway[0].id
  parent_id   = aws_api_gateway_rest_api.api_gateway[0].root_resource_id
  path_part   = trim(each.value.path, "/")
}

resource "aws_api_gateway_method" "lambda_methods" {
  for_each = merge([
    for handler_name, handler in local.rest_handlers : {
      for method, path in handler.http : "${handler_name}_${method}" => {
        name   = handler_name
        method = upper(method)
        path   = path
      }
    }
  ]...)

  rest_api_id = aws_api_gateway_rest_api.api_gateway[0].id
  resource_id = (
    each.value.path == "/" ?
    aws_api_gateway_rest_api.api_gateway[0].root_resource_id :
    aws_api_gateway_resource.lambda_resources["${each.value.name}_${each.value.method}"].id
  )
  http_method   = each.value.method
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integrations" {
  for_each = merge([
    for handler_name, handler in local.rest_handlers : {
      for method, path in handler.http : "${handler_name}_${method}" => {
        name   = handler_name
        method = upper(method)
        path   = path
      }
    }
  ]...)
  rest_api_id = aws_api_gateway_rest_api.api_gateway[0].id
  resource_id = (each.value.path == "/" ?
    aws_api_gateway_rest_api.api_gateway[0].root_resource_id :
    aws_api_gateway_resource.lambda_resources["${each.value.name}_${each.value.method}"].id
  )

  http_method             = each.value.method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.handlers[each.value.name].invoke_arn

  depends_on = [aws_api_gateway_method.lambda_methods]
}

# API Policy for allowing specific VPCE's to execute the API.
# An all-access policy is also created for EDGE / REGIONAL. 

# If there is not always a policy in place, even when not needed, switching between PRIVATE and EDGE / REGIONAL endpoints
# causes either terraform or API gateway to have issues with keeping the policy up to date.
# Specifying it explicitly seems to circumvent those problems.
locals {
  should_require_vpc = length(coalesce(try(var.rest_api.vpc_endpoint_ids, null), [])) > 0
}

resource "aws_api_gateway_rest_api_policy" "api_policy" {
  count       = local.api_gateway_version == "v1" ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.api_gateway[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "execute-api:Invoke"
        Resource = "${aws_api_gateway_rest_api.api_gateway[0].execution_arn}/*"
        Condition = local.should_require_vpc ? {
          StringLike = {
            "aws:SourceVpce" = var.rest_api.vpc_endpoint_ids
          }
        } : {}
      }
    ]
  })
}

resource "aws_api_gateway_deployment" "api_deployment" {
  count       = local.api_gateway_version == "v1" ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.api_gateway[0].id

  triggers = {
    redeployment = jsonencode({
      rest_api_id = aws_api_gateway_rest_api.api_gateway[0]
      policy      = aws_api_gateway_rest_api_policy.api_policy
      resources = {
        for k, v in aws_api_gateway_resource.lambda_resources : k => v.id
      }
      methods = {
        for k, v in aws_api_gateway_method.lambda_methods : k => v.id
      }
      integrations = {
        for k, v in aws_api_gateway_integration.lambda_integrations : k => v.id
    } })
  }

  depends_on = [
    aws_api_gateway_rest_api.api_gateway,
    aws_api_gateway_resource.lambda_resources,
    aws_api_gateway_method.lambda_methods,
    aws_api_gateway_integration.lambda_integrations,
    aws_apigatewayv2_domain_name.custom_domain,
    aws_api_gateway_rest_api_policy.api_policy,
    aws_api_gateway_integration_response.options,
    aws_api_gateway_method_response.cors
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stage" {
  count         = local.api_gateway_version == "v1" ? 1 : 0
  deployment_id = aws_api_gateway_deployment.api_deployment[0].id
  rest_api_id   = aws_api_gateway_rest_api.api_gateway[0].id
  stage_name    = "default"
}

resource "aws_api_gateway_base_path_mapping" "mapping" {
  count       = local.api_gateway_version == "v1" && local.create_domain ? 1 : 0
  api_id      = aws_api_gateway_rest_api.api_gateway[0].id
  stage_name  = aws_api_gateway_stage.stage[0].stage_name
  domain_name = aws_apigatewayv2_domain_name.custom_domain[0].domain_name
}

resource "aws_api_gateway_method_settings" "settings" {
  count = local.api_gateway_version == "v1" ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.api_gateway[0].id
  stage_name  = aws_api_gateway_stage.stage[0].stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = false
  }
}

# OPTIONS method for CORS
resource "aws_api_gateway_method" "options" {
  for_each = local.cors_resources

  rest_api_id   = aws_api_gateway_rest_api.api_gateway[0].id
  resource_id   = each.value
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# OPTIONS method response
resource "aws_api_gateway_method_response" "options" {
  for_each = local.cors_resources

  rest_api_id = aws_api_gateway_rest_api.api_gateway[0].id
  resource_id = each.value
  http_method = aws_api_gateway_method.options[each.key].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = true
    "method.response.header.Access-Control-Allow-Methods"     = true
    "method.response.header.Access-Control-Allow-Origin"      = true
    "method.response.header.Access-Control-Allow-Credentials" = true
    "method.response.header.Access-Control-Expose-Headers"    = true
    "method.response.header.Access-Control-Max-Age"           = true
  }
}

# OPTIONS integration
resource "aws_api_gateway_integration" "options" {
  for_each = local.cors_resources

  rest_api_id = aws_api_gateway_rest_api.api_gateway[0].id
  resource_id = each.value
  http_method = aws_api_gateway_method.options[each.key].http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

# OPTIONS integration response
resource "aws_api_gateway_integration_response" "options" {
  for_each = local.cors_resources

  rest_api_id = aws_api_gateway_rest_api.api_gateway[0].id
  resource_id = each.value
  http_method = aws_api_gateway_method.options[each.key].http_method
  status_code = aws_api_gateway_method_response.options[each.key].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = "'${join(",", local.cors_config.allow_headers)}'"
    "method.response.header.Access-Control-Allow-Methods"     = "'${join(",", local.cors_config.allow_methods)}'"
    "method.response.header.Access-Control-Allow-Origin"      = "'${join(",", local.cors_config.allow_origins)}'"
    "method.response.header.Access-Control-Allow-Credentials" = "'${local.cors_config.allow_credentials}'"
    "method.response.header.Access-Control-Expose-Headers"    = "'${join(",", local.cors_config.expose_headers)}'"
    "method.response.header.Access-Control-Max-Age"           = "'${local.cors_config.max_age}'"
  }

  depends_on = [aws_api_gateway_integration.options]
}

# Add CORS headers to regular methods
resource "aws_api_gateway_method_response" "cors" {
  for_each = local.cors_config != null ? merge([
    for handler_name, handler in local.rest_handlers : {
      for method, path in handler.http : "${handler_name}_${method}" => {
        name   = handler_name
        method = upper(method)
        path   = path
      }
    }
  ]...) : {}

  rest_api_id = aws_api_gateway_rest_api.api_gateway[0].id
  resource_id = each.value.path == "/" ? aws_api_gateway_rest_api.api_gateway[0].root_resource_id : aws_api_gateway_resource.lambda_resources["${each.value.name}_${each.value.method}"].id
  http_method = each.value.method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"      = true
    "method.response.header.Access-Control-Allow-Credentials" = true
  }

  depends_on = [aws_api_gateway_method.lambda_methods]
}