provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

resource "aws_acm_certificate" "edge_domain_cert" {
  count             = local.create_domain && local.domain_type == "EDGE" ? 1 : 0
  domain_name       = local.custom_domain
  provider          = aws.us_east_1
  validation_method = "DNS"
}

resource "aws_acm_certificate" "regional_domain_cert" {
  count             = local.create_domain && local.domain_type == "REGIONAL" ? 1 : 0
  domain_name       = local.custom_domain
  validation_method = "DNS"
}


# resource "aws_acm_certificate_validation" "cert_validation" {
#   count = local.create_domain ? 1 : 0
#   certificate_arn         = local.domain_type == "REGIONAL" ? aws_acm_certificate.regional_domain_cert[0].arn : aws_acm_certificate.edge_domain_cert[0].arn
#   validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

#   depends_on = [
#     aws_acm_certificate.edge_domain_cert,
#     aws_acm_certificate.regional_domain_cert,
#     aws_route53_record.cert_validation
#   ]
# }

# resource "aws_route53_record" "edge_cert_validation" {
#   count = local.create_domain && local.domain_type == "EDGE" ? 1 : 0
#   name    = tolist(aws_acm_certificate.edge_domain_cert[0].domain_validation_options)[0].resource_record_name
#   type    = tolist(aws_acm_certificate.edge_domain_cert[0].domain_validation_options)[0].resource_record_type
#   zone_id = local.zone_id
#   records = [tolist(aws_acm_certificate.edge_domain_cert[0].domain_validation_options)[0].resource_record_value]
#   ttl     = 60

#   depends_on = [
#     aws_acm_certificate.edge_domain_cert,
#   ]

#   lifecycle {
#     create_before_destroy = false
#   }
# }

# resource "aws_acm_certificate_validation" "edge_cert_validation" {
#   count = local.create_domain && local.domain_type == "EDGE" ? 1 : 0
#   certificate_arn         = aws_acm_certificate.edge_domain_cert[0].arn
#   validation_record_fqdns = [for record in aws_route53_record.cert_validation_record : record.fqdn]
#   provider          = aws.us_east_1

#   depends_on = [
#     aws_route53_record.cert_validation_record,
#   ]
# }

# resource "aws_acm_certificate_validation" "regional_cert_validation" {
#   count = local.create_domain && local.domain_type == "REGIONAL" ? 1 : 0
#   certificate_arn         = aws_acm_certificate.regional_domain_cert[0].arn
#   validation_record_fqdns = [for record in aws_route53_record.cert_validation_record : record.fqdn]

#   depends_on = [
#     aws_route53_record.cert_validation_record,
#   ]
# }

resource "aws_route53_record" "cert_validation_record" {
  count = local.create_domain ? 1 : 0
  name    = local.domain_type == "REGIONAL" ? tolist(aws_acm_certificate.regional_domain_cert[0].domain_validation_options)[0].resource_record_name : tolist(aws_acm_certificate.edge_domain_cert[0].domain_validation_options)[0].resource_record_name
  type    = local.domain_type == "REGIONAL" ? tolist(aws_acm_certificate.regional_domain_cert[0].domain_validation_options)[0].resource_record_type : tolist(aws_acm_certificate.edge_domain_cert[0].domain_validation_options)[0].resource_record_type
  zone_id = local.zone_id
  records = local.domain_type == "REGIONAL" ? [tolist(aws_acm_certificate.regional_domain_cert[0].domain_validation_options)[0].resource_record_value] : [tolist(aws_acm_certificate.edge_domain_cert[0].domain_validation_options)[0].resource_record_value]
  ttl     = 60

  depends_on = [
    aws_acm_certificate.regional_domain_cert,
    aws_acm_certificate.edge_domain_cert,
  ]

  lifecycle {
    create_before_destroy = false
  }
}