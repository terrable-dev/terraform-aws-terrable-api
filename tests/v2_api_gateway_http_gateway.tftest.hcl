mock_provider "aws" {
  source = "./tests/mocks"
}

variables {
  api_name = "test-api"
  http_api = {
    custom_domain  = "testdomain.test.com"
    hosted_zone_id = "HZID"
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

run "validation_requires_hosted_zone" {
  command = plan

  variables {
    api_name = "test-api"
    http_api = {
      custom_domain = "testdomain.test.com"
      # deliberately omitting hosted_zone_id
    }
  }

  expect_failures = [
    var.http_api,
  ]
}


run "creates_http_api_custom_domain" {
  assert {
    condition     = aws_apigatewayv2_domain_name.custom_domain[0].domain_name == var.http_api.custom_domain
    error_message = "Custom domain name does not match the expected value"
  }
}

run "creates_api_mapping" {
  assert {
    condition     = aws_apigatewayv2_api_mapping.custom_domain_mapping[0].domain_name == aws_apigatewayv2_domain_name.custom_domain[0].id
    error_message = "API mapping domain name does not match the expected value"
  }
}

run "creates_custom_domain" {
  assert {
    condition     = aws_apigatewayv2_domain_name.custom_domain[0].domain_name == var.http_api.custom_domain
    error_message = "Custom domain name does not match the expected value"
  }
}

run "creates_route53_record" {
  assert {
    condition     = aws_route53_record.api_domain[0].alias[0].name == aws_apigatewayv2_domain_name.custom_domain[0].domain_name_configuration[0].target_domain_name
    error_message = "Route53 record for custom domain not created correctly"
  }
}

run "route53_record_uses_correct_zone" {
  assert {
    condition     = aws_route53_record.api_domain[0].zone_id == var.http_api.hosted_zone_id
    error_message = "Route53 record is not using the provided hosted zone ID"
  }
}

run "custom_domain_configuration" {
  assert {
    condition     = aws_apigatewayv2_domain_name.custom_domain[0].domain_name_configuration[0].endpoint_type == "REGIONAL"
    error_message = "Custom domain not configured as REGIONAL endpoint"
  }
}

run "api_stage_auto_deploy" {
  assert {
    condition     = aws_apigatewayv2_stage.default[0].auto_deploy == true
    error_message = "API stage auto deploy not enabled"
  }
}

run "api_stage_linked_to_custom_domain" {
  assert {
    condition     = aws_apigatewayv2_api_mapping.custom_domain_mapping[0].stage == aws_apigatewayv2_stage.default[0].id
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
    condition     = aws_acm_certificate.domain_cert[0].domain_name == var.http_api.custom_domain
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

run "certificate_validation_record_uses_correct_zone" {
  assert {
    condition     = aws_route53_record.cert_validation[0].zone_id == var.http_api.hosted_zone_id
    error_message = "Certificate validation record is not using the provided hosted zone ID"
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
