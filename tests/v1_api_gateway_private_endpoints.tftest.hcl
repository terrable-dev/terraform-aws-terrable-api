mock_provider "aws" {
  source = "./tests/mocks"
}

variables {
  api_name = "test-api"
  runtime  = "nodejs20.x"

  rest_api = {
    endpoint_type = "PRIVATE"
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

run "endpoint_configuration_is_private" {
  assert {
    condition     = aws_api_gateway_rest_api.api_gateway[0].endpoint_configuration[0].types[0] == "PRIVATE"
    error_message = "API Gateway endpoint type configuration should be 'PRIVATE'"
  }
}

run "domain_name_not_configured_for_private" {
  assert {
    condition     = length(aws_apigatewayv2_domain_name.custom_domain) == 0
    error_message = "Custom domain name should not be configured for 'PRIVATE' API Gateways"
  }
}