locals {
  sanitised_http_handlers = {
    for k, v in local.rest_handlers : k => {
      source = v.source
      http = {
        for method, path in v.http : method => path
      }
    }
  }
}

resource "aws_api_gateway_rest_api" "api_gateway" {
  count = local.api_gateway_version == "v1" ? 1 : 0
  name  = var.api_name
  tags  = try(var.rest_api.tags, null)

  endpoint_configuration {
    types = [var.rest_api.endpoint_type]
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

resource "aws_api_gateway_method_settings" "settings" {
  count = local.api_gateway_version == "v1" ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.api_gateway[0].id
  stage_name  = "default"
  method_path = "*/*"

  settings {
    metrics_enabled = false
  }

  depends_on = [aws_api_gateway_deployment.api_deployment]
}

resource "aws_api_gateway_deployment" "api_deployment" {
  count = local.api_gateway_version == "v1" ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.api_gateway[0].id
  stage_name  = "default"

  depends_on = [
    aws_api_gateway_integration.lambda_integrations,
    aws_api_gateway_resource.lambda_resources,
    aws_api_gateway_method.lambda_methods,
    aws_api_gateway_rest_api.api_gateway,
  ]

  triggers = {
    redeployment = sha1(jsonencode({
      rest_api     = aws_api_gateway_rest_api.api_gateway[0],
      resources    = aws_api_gateway_resource.lambda_resources,
      methods      = aws_api_gateway_method.lambda_methods,
      integrations = aws_api_gateway_integration.lambda_integrations,
    }))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_domain_name" "custom_domain" {
  count                    = local.api_gateway_version == "v1" && local.create_domain ? 1 : 0
  domain_name              = local.custom_domain
  regional_certificate_arn = local.create_certificate ? aws_acm_certificate.domain_cert[0].arn : local.certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  depends_on = [
    aws_acm_certificate_validation.cert_validation,
    aws_apigatewayv2_domain_name.custom_domain
  ]
}

resource "aws_api_gateway_base_path_mapping" "mapping" {
  count       = local.api_gateway_version == "v1" && local.create_domain ? 1 : 0
  api_id      = aws_api_gateway_rest_api.api_gateway[0].id
  stage_name  = aws_api_gateway_deployment.api_deployment[0].stage_name
  domain_name = aws_api_gateway_domain_name.custom_domain[0].domain_name
}
