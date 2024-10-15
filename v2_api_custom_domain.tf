resource "aws_acm_certificate" "domain_cert" {
  count             = local.create_certificate ? 1 : 0
  domain_name       = var.http_api.custom_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "domain_zone" {
  count = local.http_custom_domain != null ? 1 : 0
  name  = join(".", slice(split(".", var.http_api.custom_domain), 1, length(split(".", var.http_api.custom_domain))))
}

resource "aws_apigatewayv2_domain_name" "custom_domain" {
  count       = local.http_custom_domain != null ? 1 : 0
  domain_name = local.http_custom_domain

  domain_name_configuration {
    certificate_arn = local.create_certificate ? aws_acm_certificate.domain_cert[0].arn : var.http_api.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  depends_on = [
    aws_acm_certificate_validation.cert_validation,
  ]
}

resource "aws_apigatewayv2_api_mapping" "custom_domain_mapping" {
  count       = local.http_custom_domain != null ? 1 : 0
  api_id      = aws_apigatewayv2_api.api_gateway[0].id
  domain_name = aws_apigatewayv2_domain_name.custom_domain[0].id
  stage       = aws_apigatewayv2_stage.default[0].id

  depends_on = [
    aws_apigatewayv2_domain_name.custom_domain,
  ]
}

resource "aws_acm_certificate_validation" "cert_validation" {
  count                   = local.create_certificate ? 1 : 0
  certificate_arn         = aws_acm_certificate.domain_cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  depends_on = [
    aws_route53_record.cert_validation,
  ]
}

resource "aws_route53_record" "cert_validation" {
  count   = local.create_certificate ? 1 : 0
  name    = tolist(aws_acm_certificate.domain_cert[0].domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.domain_cert[0].domain_validation_options)[0].resource_record_type
  zone_id = data.aws_route53_zone.domain_zone[0].zone_id
  records = [tolist(aws_acm_certificate.domain_cert[0].domain_validation_options)[0].resource_record_value]
  ttl     = 60

  depends_on = [
    aws_acm_certificate.domain_cert,
  ]
}

resource "aws_route53_record" "api_domain" {
  count   = local.http_custom_domain != null ? 1 : 0
  zone_id = data.aws_route53_zone.domain_zone[0].zone_id
  name    = var.http_api.custom_domain
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.custom_domain[0].domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.custom_domain[0].domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [
    aws_apigatewayv2_domain_name.custom_domain,
  ]
}
