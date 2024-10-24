mock_provider "aws" {
  source = "./tests/mocks"
}

variables {
  api_name = "test-api"
  rest_api = {

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

run "api_deployment_created" {
  assert {
    condition     = length(aws_api_gateway_deployment.api_deployment) > 0
    error_message = "API deployment not created"
  }
}

run "api_deployment_stage_name" {
  assert {
    condition     = aws_api_gateway_deployment.api_deployment[0].stage_name == "default"
    error_message = "API deployment stage name is not 'default'"
  }
}

run "default_endpoint_configuration_is_regional" {
  assert {
    condition = aws_api_gateway_rest_api.api_gateway[0].endpoint_configuration[0].types[0] == "REGIONAL"
    error_message = "Default endpoint type configuration should be 'REGIONAL'"
  }
}