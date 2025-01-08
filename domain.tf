resource "aws_apigatewayv2_domain_name" "custom_domain" {
  count       = local.create_domain ? 1 : 0
  domain_name = local.custom_domain

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.domain_cert[0].arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  lifecycle {
    create_before_destroy = false
  }

  depends_on = [
    aws_acm_certificate_validation.cert_validation,
  ]
}

resource "aws_route53_record" "api_domain" {
  count   = local.create_domain ? 1 : 0
  zone_id = data.aws_route53_zone.domain_zone[0].zone_id
  name    = local.custom_domain
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.custom_domain[0].domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.custom_domain[0].domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}
