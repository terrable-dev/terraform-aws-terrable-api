mock_provider "aws" {
  source = "./tests/mocks"
}

variables {
  api_name = "test-api"
  rest_api = {
    custom_domain = "testdomain.test.com"
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

run "base_path_mapping_uses_default_stage" {
  assert {
    condition     = aws_api_gateway_base_path_mapping.mapping[0].stage_name == "default"
    error_message = "Base path mapping is not using 'default' stage"
  }
}
