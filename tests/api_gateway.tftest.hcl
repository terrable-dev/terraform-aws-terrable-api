mock_provider "aws" {
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/example-role"
    }
  }

  mock_resource "aws_lambda_permission" {
    defaults = {
      arn = "arn:aws:execute-api:us-east-1:123456789012:abcdef123/*/GET/test"
    }
  }

  mock_resource "aws_lambda_function" {
    defaults = {
      invoke_arn = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:test-function/invocations"
    }
  }

  mock_resource "aws_apigatewayv2_api" {
    defaults = {
      execution_arn = "arn:aws:execute-api:us-east-1:123456789012:abcdef123"
    }
  }
}

variables {
  api_name = "test-api"
  handlers = {
    TestHandler : {
      source = "./tests/handler.js"
      http = {
        method = "GET"
        path   = "/"
      }
    }
  }
}

run "lambda_function_names" {
  assert {
    condition     = aws_lambda_function.handlers["TestHandler"].function_name == "${var.api_name}-TestHandler"
    error_message = "incorrect Lambda function name"
  }
}

run "api_gateway_has_correct_name" {
  assert {
    condition     = aws_apigatewayv2_api.api_gateway.name == "test-api"
    error_message = "incorrect API Gateway name"
  }
}

run "default_stage_name" {
  assert {
    condition     = aws_apigatewayv2_stage.default.name == "$default"
    error_message = "Default stage name not set"
  }
}

run "cloudwatch_log_group_created" {
  assert {
    condition     = aws_cloudwatch_log_group.lambda_log_groups["TestHandler"].name == "/aws/lambda/test-api-TestHandler"
    error_message = "CloudWatch Log Group name is incorrect"
  }
}

run "all_routes_added" {
  assert {
    condition = alltrue([
      for key, handler in var.handlers :
      contains(keys(aws_apigatewayv2_route.lambda_routes), key) &&
      aws_apigatewayv2_route.lambda_routes[key].route_key == "${handler.http.method} ${handler.http.path}"
    ])

    error_message = "One or more routes have not been mapped"
  }

  assert {
    condition     = length(keys(aws_apigatewayv2_route.lambda_routes)) == length(keys(var.handlers))
    error_message = "One or more routes have not been mapped"
  }
}
