resource "aws_api_gateway_domain_name" "custom_domain" {
  count           = local.create_domain ? 1 : 0
  domain_name     = local.custom_domain
  certificate_arn = local.domain_type == "EDGE" ? aws_acm_certificate.edge_domain_cert[0].arn : null
  regional_certificate_arn = local.domain_type == "REGIONAL" ? aws_acm_certificate.regional_domain_cert[0].arn : null

  endpoint_configuration {
    types = [local.domain_type]
  }

  security_policy = "TLS_1_2"

  depends_on = [
    aws_acm_certificate.edge_domain_cert,
    aws_acm_certificate.regional_domain_cert,
    aws_route53_record.cert_validation_record,
  ]

  lifecycle {
    create_before_destroy = false
  }
}

# resource "aws_api_gateway_domain_name" "regional_custom_domain" {
#   count           = local.create_domain && local.domain_type == "REGIONAL" ? 1 : 0
#   domain_name     = local.custom_domain
#   regional_certificate_arn = aws_acm_certificate.regional_domain_cert[0].arn

#   endpoint_configuration {
#     types = ["REGIONAL"]
#   }

#   security_policy = "TLS_1_2"

#   depends_on = [
#     aws_acm_certificate.edge_domain_cert,
#     aws_acm_certificate.regional_domain_cert,
#     aws_route53_record.cert_validation_record,
#   ]

#   lifecycle {
#     create_before_destroy = false
#   }
# }

# resource "aws_api_gateway_domain_name" "custom_domain" {
#   count           = local.create_domain ? 1 : 0
#   domain_name     = local.custom_domain
#   regional_certificate_arn = local.domain_type == "REGIONAL" ? aws_acm_certificate.regional_domain_cert[0].arn : null
#   certificate_arn = local.domain_type == "EDGE" ? aws_acm_certificate.edge_domain_cert[0].arn : null

#   endpoint_configuration {
#     types = [local.domain_type]
#   }

#   security_policy = "TLS_1_2"

#   depends_on = [
#     aws_acm_certificate.edge_domain_cert,
#     aws_acm_certificate.regional_domain_cert,
#     aws_route53_record.cert_validation_record,
#     aws_api_gateway_rest_api.api_gateway,
#   ]

#   lifecycle {
#     create_before_destroy = false
#   }
# }

resource "aws_route53_record" "api_domain" {
  count   = local.create_domain ? 1 : 0
  zone_id = local.zone_id
  name    = local.custom_domain
  type    = "A"

  alias {
    name = coalesce(
      local.domain_type == "EDGE" ? aws_api_gateway_domain_name.custom_domain[0].cloudfront_domain_name : "",
      local.domain_type == "REGIONAL" ? aws_api_gateway_domain_name.custom_domain[0].regional_domain_name : "",
      "dummy.example.com" # Fallback value that will never be used in practice
    )
    zone_id = coalesce(
      local.domain_type == "EDGE" ? aws_api_gateway_domain_name.custom_domain[0].cloudfront_zone_id : "",
      local.domain_type == "REGIONAL" ? aws_api_gateway_domain_name.custom_domain[0].regional_zone_id : "",
      "dummy" # Fallback value that will never be used in practice
    )
    evaluate_target_health = false
  }

  depends_on = [
    aws_api_gateway_domain_name.custom_domain,
    aws_acm_certificate.edge_domain_cert,
    aws_acm_certificate.regional_domain_cert,
    aws_route53_record.cert_validation_record,
  ]
}