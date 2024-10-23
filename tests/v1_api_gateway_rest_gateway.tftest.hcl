mock_provider "aws" {
  source = "./tests/mocks"
}

variables {
  api_name = "test-api"
  rest_api = {
    custom_domain = "test.domain.coms"
  }
  handlers = {
    TestHandler : {
      source = "./tests/handler.js"
      http = {
        GET = "/"
      }
    }
  }
}

run "creates_rest_api_custom_domain" {
  assert {
    condition     = aws_api_gateway_domain_name.custom_domain[0].domain_name == var.rest_api.custom_domain
    error_message = "Custom domain name does not match the expected value"
  }
}

run "creates_base_path_mapping" {
  assert {
    condition     = aws_api_gateway_base_path_mapping.mapping[0].domain_name == aws_api_gateway_domain_name.custom_domain[0].domain_name
    error_message = "Base path mapping domain name does not match the expected value"
  }
}

run "creates_custom_domain" {
  assert {
    condition     = aws_api_gateway_domain_name.custom_domain[0].domain_name == var.rest_api.custom_domain
    error_message = "Custom domain name does not match the expected value"
  }
}

run "creates_route53_record" {
  assert {
    condition     = aws_route53_record.api_domain[0].name == aws_api_gateway_domain_name.custom_domain[0].domain_name
    error_message = "Route53 record for custom domain not created correctly"
  }
}

run "custom_domain_configuration" {
  assert {
    condition     = contains(aws_api_gateway_domain_name.custom_domain[0].endpoint_configuration[0].types, "REGIONAL")
    error_message = "Custom domain not configured as REGIONAL endpoint"
  }
}

run "api_stage_linked_to_custom_domain" {
  assert {
    condition     = aws_api_gateway_base_path_mapping.mapping[0].stage_name == aws_api_gateway_deployment.api_deployment[0].stage_name
    error_message = "API stage not correctly linked to custom domain"
  }
}

run "acm_certificate_created" {
  assert {
    condition     = length(aws_acm_certificate.domain_cert) > 0
    error_message = "ACM certificate was not created"
  }
}

run "acm_certificate_domain_name" {
  assert {
    condition     = aws_acm_certificate.domain_cert[0].domain_name == var.rest_api.custom_domain
    error_message = "ACM certificate domain name does not match the custom domain"
  }
}

run "acm_certificate_validation_method" {
  assert {
    condition     = aws_acm_certificate.domain_cert[0].validation_method == "DNS"
    error_message = "ACM certificate validation method is not DNS"
  }
}

run "custom_domain_uses_correct_certificate" {
  assert {
    condition     = aws_api_gateway_domain_name.custom_domain[0].regional_certificate_arn == aws_acm_certificate.domain_cert[0].arn
    error_message = "Custom domain is not using the correct ACM certificate"
  }
}

run "certificate_validation_record_created" {
  assert {
    condition     = length(aws_route53_record.cert_validation) > 0
    error_message = "Certificate validation DNS record was not created"
  }
}

run "certificate_validation_record_matches_certificate" {
  assert {
    condition     = aws_route53_record.cert_validation[0].name == tolist(aws_acm_certificate.domain_cert[0].domain_validation_options)[0].resource_record_name
    error_message = "Certificate validation DNS record name does not match the certificate's validation options"
  }
}

run "certificate_validation_created" {
  assert {
    condition     = length(aws_acm_certificate_validation.cert_validation) > 0
    error_message = "ACM certificate validation resource was not created"
  }
}

run "certificate_validation_links_to_correct_certificate" {
  assert {
    condition     = aws_acm_certificate_validation.cert_validation[0].certificate_arn == aws_acm_certificate.domain_cert[0].arn
    error_message = "ACM certificate validation is not linked to the correct certificate"
  }
}
<<<<<<< HEAD
=======

run "deployment_uses_default_stage" {
  assert {
    condition     = aws_api_gateway_deployment.api_deployment[0].stage_name == "default"
    error_message = "API Gateway deployment is not using 'default' stage"
  }
}

run "method_settings_use_default_stage" {
  assert {
    condition     = aws_api_gateway_method_settings.settings[0].stage_name == "default"
    error_message = "API Gateway method settings are not applied to 'default' stage"
  }
}

run "base_path_mapping_uses_default_stage" {
  assert {
    condition     = aws_api_gateway_base_path_mapping.mapping[0].stage_name == "default"
    error_message = "Base path mapping is not using 'default' stage"
  }
}

run "deployment_stage_name_is_default" {
  assert {
    condition     = aws_api_gateway_deployment.api_deployment[0].stage_name == "default"
    error_message = "Deployment stage name is not set to 'default'"
  }
}

run "deployment_rest_api_id" {
  assert {
    condition     = aws_api_gateway_deployment.api_deployment[0].rest_api_id == aws_api_gateway_rest_api.api_gateway[0].id
    error_message = "Deployment is not associated with the correct REST API"
  }
}

run "method_settings_applied_to_all_methods" {
  assert {
    condition     = aws_api_gateway_method_settings.settings[0].method_path == "*/*"
    error_message = "Method settings are not applied to all methods"
  }
}

run "method_settings_rest_api_id" {
  assert {
    condition     = aws_api_gateway_method_settings.settings[0].rest_api_id == aws_api_gateway_rest_api.api_gateway[0].id
    error_message = "Method settings are not associated with the correct REST API"
  }
}
>>>>>>> 26e20b8bdfff16f83df35c241b2b8330c6277d70
