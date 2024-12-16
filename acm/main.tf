terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

resource "aws_acm_certificate" "edge_domain_cert" {
  count             = var.domain_type == "EDGE" ? 1 : 0
  domain_name       = var.custom_domain
  provider          = aws.us_east_1
    validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "regional_domain_cert" {
  count             = var.domain_type == "REGIONAL" ? 1 : 0
  domain_name       = var.custom_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "edge_cert_validation" {
  count = var.domain_type == "EDGE" ? 1 : 0
  name    = tolist(aws_acm_certificate.edge_domain_cert[0].domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.edge_domain_cert[0].domain_validation_options)[0].resource_record_type
  zone_id = var.zone_id
  records = [tolist(aws_acm_certificate.edge_domain_cert[0].domain_validation_options)[0].resource_record_value]
  ttl     = 60

  depends_on = [
    aws_acm_certificate.edge_domain_cert,
  ]
}

resource "aws_route53_record" "regional_cert_validation" {
  count = var.domain_type == "REGIONAL" ? 1 : 0
  name    = tolist(aws_acm_certificate.regional_domain_cert[0].domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.regional_domain_cert[0].domain_validation_options)[0].resource_record_type
  zone_id = var.zone_id
  records = [tolist(aws_acm_certificate.regional_domain_cert[0].domain_validation_options)[0].resource_record_value]
  ttl     = 60

  depends_on = [
    aws_acm_certificate.regional_domain_cert,
  ]
}

resource "aws_acm_certificate_validation" "edge_cert_validation" {
  count = var.domain_type == "EDGE" ? 1 : 0
  certificate_arn         = aws_acm_certificate.edge_domain_cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.edge_cert_validation : record.fqdn]
  provider          = aws.us_east_1

  depends_on = [
    aws_route53_record.edge_cert_validation,
  ]
}

resource "aws_acm_certificate_validation" "regional_cert_validation" {
  count = var.domain_type == "REGIONAL" ? 1 : 0
  certificate_arn         = aws_acm_certificate.regional_domain_cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.regional_cert_validation : record.fqdn]

  depends_on = [
    aws_route53_record.regional_cert_validation,
  ]
}
