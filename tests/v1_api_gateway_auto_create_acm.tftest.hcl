mock_provider "aws" {
  source = "./tests/mocks"
}

variables {
  api_name = "test-api"
  runtime  = "nodejs20.x"

  rest_api = {
    custom_domain  = "testdomain.test.com"
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
    condition     = aws_apigatewayv2_domain_name.custom_domain[0].domain_name == var.rest_api.custom_domain
    error_message = "Custom domain name does not match the expected value"
  }
}

run "creates_base_path_mapping" {
  assert {
    condition     = aws_api_gateway_base_path_mapping.mapping[0].domain_name == aws_apigatewayv2_domain_name.custom_domain[0].domain_name
    error_message = "Base path mapping domain name does not match the expected value"
  }
}

run "creates_custom_domain" {
  assert {
    condition     = aws_apigatewayv2_domain_name.custom_domain[0].domain_name == var.rest_api.custom_domain
    error_message = "Custom domain name does not match the expected value"
  }
}

run "creates_route53_record" {
  assert {
    condition     = aws_route53_record.api_domain[0].name == aws_apigatewayv2_domain_name.custom_domain[0].domain_name
    error_message = "Route53 record for custom domain not created correctly"
  }
}

run "custom_domain_configuration" {
  assert {
    condition     = aws_apigatewayv2_domain_name.custom_domain[0].domain_name_configuration[0].endpoint_type == "REGIONAL"
    error_message = "Custom domain not configured as REGIONAL endpoint"
  }
}

run "api_stage_linked_to_custom_domain" {
  assert {
    condition     = aws_api_gateway_base_path_mapping.mapping[0].stage_name == aws_api_gateway_stage.stage[0].stage_name
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
    condition     = aws_apigatewayv2_domain_name.custom_domain[0].domain_name_configuration[0].certificate_arn == aws_acm_certificate.domain_cert[0].arn
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

run "base_path_mapping_uses_default_stage" {
  assert {
    condition     = aws_api_gateway_base_path_mapping.mapping[0].stage_name == "default"
    error_message = "Base path mapping is not using 'default' stage"
  }
}