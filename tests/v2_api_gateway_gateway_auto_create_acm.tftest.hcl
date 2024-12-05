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
