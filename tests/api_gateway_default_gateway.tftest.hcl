mock_provider "aws" {
  source = "./tests/mocks"
}

variables {
  api_name = "test-api"
  runtime  = "nodejs20.x"

  handlers = {
    TestHandler : {
      source = "./tests/handler.js"
      http = {
        GET = "/"
      }
    }
  }
}

run "api_gateway_has_correct_name" {
  assert {
    condition     = aws_apigatewayv2_api.api_gateway[0].name == "test-api"
    error_message = "incorrect API Gateway name"
  }
}

run "default_stage_name" {
  assert {
    condition     = aws_apigatewayv2_stage.default[0].name == "$default"
    error_message = "default stage name not set"
  }
}

run "lambda_function_names" {
  assert {
    condition = alltrue([
      for key, handler in var.handlers :
      aws_lambda_function.handlers[key].function_name == format("%s-TestHandler", var.api_name)
    ])

    error_message = "expected cloudwatch log groups not created"
  }
}

run "cloudwatch_log_groups_created" {
  assert {
    condition = alltrue([
      for key, handler in var.handlers :
      aws_cloudwatch_log_group.lambda_log_groups[key].name == format("/aws/lambda/test-api-%s", key)
    ])

    error_message = "expected cloudwatch log groups not created"
  }
}

run "attach_lambda_role" {
  assert {
    condition = alltrue([
      for key, handler in var.handlers :
      aws_lambda_function.handlers[key].role == aws_iam_role.lambda_role.arn
    ])

    error_message = "lambda roles not attached"
  }
}

run "all_routes_added" {
  assert {
    condition = alltrue([
      for handler_name, handler in var.handlers :
      alltrue([
        for method, path in handler.http :
        contains(keys(aws_apigatewayv2_route.lambda_routes), "${handler_name}_${method}") &&
        aws_apigatewayv2_route.lambda_routes["${handler_name}_${method}"].route_key == "${upper(method)} ${path}"
      ])
    ])

    error_message = "one or more routes have not been mapped correctly"
  }

  assert {
    condition = length(keys(aws_apigatewayv2_route.lambda_routes)) == sum([
      for handler in values(var.handlers) : length(keys(handler.http))
    ])
    error_message = "the number of routes doesn't match the number of defined HTTP methods across all handlers"
  }
}

run "verify_lambda_basic_execution_role" {
  assert {
    condition     = aws_iam_role_policy_attachment.lambda_logs.policy_arn == "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    error_message = "AWSLambdaBasicExecutionRole is not correctly attached"
  }
}

run "lambda_role_cloudwatch_attachment" {
  assert {
    condition     = aws_iam_role_policy_attachment.lambda_logs.policy_arn == "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    error_message = "lambda cloudwatch attachment missing basic execution policy"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.lambda_logs.role == aws_iam_role.lambda_role.name
    error_message = "lambda cloudwatch attachment not attached to lambda role"
  }
}
