resource "aws_acm_certificate" "domain_cert" {
  count             = local.create_certificate ? 1 : 0
  domain_name       = local.custom_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "domain_zone" {
  count = local.custom_domain != null ? 1 : 0
  name  = join(".", slice(split(".", local.custom_domain), 1, length(split(".", local.custom_domain))))
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
