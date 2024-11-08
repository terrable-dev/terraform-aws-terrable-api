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

# API Policy - without this, when switching between PRIVATE and EDGE / REGIONAL endpoints
# eitherterraform or API gateway has issues with keeping the policy up to date.
# Specifying it explicitly seems to circumvent them.
data "aws_iam_policy_document" "api_policy_document" {
  statement {
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["execute-api:Invoke"]
    resources = ["${aws_api_gateway_rest_api.api_gateway[0].execution_arn}/*"]

    dynamic "condition" {
      for_each = coalesce(var.rest_api.vpc_endpoint_ids, [])
      content {
        test     = "StringLike"
        variable = "aws:SourceVpce"
        values   = [condition.value]
      }
    }
  }
}

resource "aws_api_gateway_rest_api_policy" "api_policy" {
  count       = local.api_gateway_version == "v1" ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.api_gateway[0].id
  policy      = data.aws_iam_policy_document.api_policy_document.json
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
    aws_api_gateway_domain_name.custom_domain,
    aws_api_gateway_rest_api_policy.api_policy,
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment[0].id
  rest_api_id   = aws_api_gateway_rest_api.api_gateway[0].id
  stage_name    = "default"
}

resource "aws_api_gateway_base_path_mapping" "mapping" {
  count       = local.api_gateway_version == "v1" && local.create_domain ? 1 : 0
  api_id      = aws_api_gateway_rest_api.api_gateway[0].id
  stage_name  = aws_api_gateway_stage.stage.stage_name
  domain_name = aws_api_gateway_domain_name.custom_domain[0].domain_name
}

resource "aws_api_gateway_method_settings" "settings" {
  count = local.api_gateway_version == "v1" ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.api_gateway[0].id
  stage_name  = aws_api_gateway_stage.stage.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = false
  }
}

// TODO:
# Test for stage resource
# Stage resource to V2
