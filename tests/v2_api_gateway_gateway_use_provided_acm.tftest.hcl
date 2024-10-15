mock_provider "aws" {
  source = "./tests/mocks"
}

variables {
  api_name = "test-api"
  http_api = {
    custom_domain   = "testdomain.test.com"
    certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/existing-cert-id"
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

run "no_new_acm_certificate_created" {
  assert {
    condition     = length(aws_acm_certificate.domain_cert) == 0
    error_message = "New ACM certificate was created when it shouldn't have been"
  }
}

run "custom_domain_uses_existing_certificate" {
  assert {
    condition     = aws_apigatewayv2_domain_name.custom_domain[0].domain_name_configuration[0].certificate_arn == var.http_api.certificate_arn
    error_message = "Custom domain is not using the existing ACM certificate"
  }
}

run "no_certificate_validation_created" {
  assert {
    condition     = length(aws_acm_certificate_validation.cert_validation) == 0
    error_message = "ACM certificate validation resource was created when it shouldn't have been"
  }
}

run "no_certificate_validation_records_created" {
  assert {
    condition     = length(aws_route53_record.cert_validation) == 0
    error_message = "Certificate validation DNS records were created when they shouldn't have been"
  }
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

run "creates_route53_record" {
  assert {
    condition     = aws_route53_record.api_domain[0].alias[0].name == aws_apigatewayv2_domain_name.custom_domain[0].domain_name_configuration[0].target_domain_name
    error_message = "Route53 record for custom domain not created correctly"
  }
}

run "custom_domain_configuration" {
  assert {
    condition     = aws_apigatewayv2_domain_name.custom_domain[0].domain_name_configuration[0].endpoint_type == "REGIONAL"
    error_message = "Custom domain not configured as REGIONAL endpoint"
  }
}
