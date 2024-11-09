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

run "stage_configured_as_default" {
  assert {
    condition     = aws_api_gateway_stage.stage[0].stage_name == "default"
    error_message = "Stage name should be set to 'default'"
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

run "method_settings_use_default_stage" {
  assert {
    condition     = aws_api_gateway_method_settings.settings[0].stage_name == "default"
    error_message = "API Gateway method settings are not applied to 'default' stage"
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

run "default_endpoint_configuration_is_regional" {
  assert {
    condition     = aws_api_gateway_rest_api.api_gateway[0].endpoint_configuration[0].types[0] == "REGIONAL"
    error_message = "Default endpoint type configuration should be 'REGIONAL'"
  }
}

run "resource_policy_set" {
  assert {
    condition     = (jsondecode(resource.aws_iam_policy.api_policy[0].policy).Statement[0].Condition) == null
    error_message = "Policy should not include any conditiopns"
  }

  assert {
    condition     = jsondecode(resource.aws_iam_policy.api_policy[0].policy).Statement[0].Action[0] == "execute-api:Invoke"
    error_message = "Policy Action should be 'execute-api:Invoke'"
  }

  assert {
    condition     = can(regex("^arn:aws:execute-api:", jsondecode(resource.aws_iam_policy.api_policy[0].policy).Statement[0].Resource[0]))
    error_message = "Policy Resource should start with 'arn:aws:execute-api:'"
  }

  assert {
    condition     = jsondecode(resource.aws_iam_policy.api_policy[0].policy).Statement[0].Principal.Type == "*"
    error_message = "Policy Principal Type should be '*'"
  }

  assert {
    condition     = jsondecode(resource.aws_iam_policy.api_policy[0].policy).Statement[0].Principal.Identifiers[0] == "*"
    error_message = "Policy Principal Identifiers should include '*'"
  }

  assert {
    condition     = jsondecode(resource.aws_iam_policy.api_policy[0].policy).Statement[0].Effect == "Allow"
    error_message = "Policy Effect should be 'Allow'"
  }
}