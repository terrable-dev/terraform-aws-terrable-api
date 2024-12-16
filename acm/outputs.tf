output "certificate" {
  value = (var.domain_type == "REGIONAL") ? try(aws_acm_certificate.regional_domain_cert[0], null) : try(aws_acm_certificate.edge_domain_cert[0], null)
}

