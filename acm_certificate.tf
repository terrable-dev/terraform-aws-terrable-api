resource "aws_acm_certificate" "domain_cert" {
  count                   = local.create_certificate ? 1 : 0
  domain_name       = local.custom_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  count   = local.create_certificate ? 1 : 0
  name    = tolist(aws_acm_certificate.domain_cert[0].domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.domain_cert[0].domain_validation_options)[0].resource_record_type
  zone_id = local.zone_id
  records = [tolist(aws_acm_certificate.domain_cert[0].domain_validation_options)[0].resource_record_value]
  ttl     = 60

  depends_on = [
    aws_acm_certificate.domain_cert,
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
