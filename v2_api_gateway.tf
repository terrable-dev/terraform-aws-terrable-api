resource "aws_apigatewayv2_stage" "default" {
  count = local.api_gateway_version == "v2" ? 1 : 0
  api_id      = aws_apigatewayv2_api.api_gateway[0].id
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

  api_id    = aws_apigatewayv2_api.api_gateway[0].id
  route_key = "${each.value.method} ${each.value.path}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integrations[each.value.handler_name].id}"
}

resource "aws_apigatewayv2_integration" "lambda_integrations" {
  for_each = local.http_handlers

  api_id             = aws_apigatewayv2_api.api_gateway[0].id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.handlers[each.key].invoke_arn
}

resource "aws_apigatewayv2_api" "api_gateway" {
  count = local.api_gateway_version == "v2" ? 1 : 0
  name          = var.api_name
  protocol_type = "HTTP"
  tags          = try(var.http_api.tags, null)
}

resource "aws_apigatewayv2_api_mapping" "custom_domain_mapping" {
  count       = local.api_gateway_version == "v2" && local.custom_domain != null ? 1 : 0
  api_id      = aws_apigatewayv2_api.api_gateway[0].id
  domain_name = aws_apigatewayv2_domain_name.custom_domain[0].id
  stage       = aws_apigatewayv2_stage.default[0].id

  depends_on = [
    aws_apigatewayv2_domain_name.custom_domain,
  ]
}

resource "aws_apigatewayv2_domain_name" "custom_domain" {
  count       = local.api_gateway_version == "v2" &&  local.custom_domain != null ? 1 : 0
  domain_name = local.custom_domain

  domain_name_configuration {
    certificate_arn = local.create_certificate ? aws_acm_certificate.domain_cert[0].arn : local.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  depends_on = [
    aws_acm_certificate_validation.cert_validation,
  ]
}
