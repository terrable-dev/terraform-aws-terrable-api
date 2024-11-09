resource "aws_route53_record" "api_domain" {
  count   = local.create_domain ? 1 : 0
  zone_id = data.aws_route53_zone.domain_zone[0].zone_id
  name    = local.custom_domain
  type    = "A"

  alias {
    name                   = local.api_gateway_version == "v1" ? aws_api_gateway_domain_name.custom_domain[0].regional_domain_name : aws_apigatewayv2_domain_name.custom_domain[0].domain_name_configuration[0].target_domain_name
    zone_id                = local.api_gateway_version == "v1" ? aws_api_gateway_domain_name.custom_domain[0].regional_zone_id : aws_apigatewayv2_domain_name.custom_domain[0].domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [
    aws_api_gateway_domain_name.custom_domain,
    aws_apigatewayv2_domain_name.custom_domain,
  ]
}
