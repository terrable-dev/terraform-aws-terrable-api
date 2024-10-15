mock_provider "aws" {
  source = "./tests/mocks"
}

variables {
  api_name = "test-api"
  vpc = {
    subnet_ids         = ["subnet-12345"]
    security_group_ids = ["sg-67890", "sg-4567"]
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

run "verify_lambda_vpc_config" {
  assert {
    condition     = length(aws_lambda_function.handlers["TestHandler"].vpc_config) == 1
    error_message = "VPC config block should be present"
  }

  assert {
    condition     = length(aws_lambda_function.handlers["TestHandler"].vpc_config[0].subnet_ids) == 1
    error_message = "Subnet IDs should contain 1 element"
  }

  assert {
    condition     = contains(aws_lambda_function.handlers["TestHandler"].vpc_config[0].subnet_ids, "subnet-12345")
    error_message = "Subnet ID does not match expected value"
  }

  assert {
    condition     = length(aws_lambda_function.handlers["TestHandler"].vpc_config[0].security_group_ids) == 2
    error_message = "Security group IDs should contain 2 element"
  }

  assert {
    condition     = contains(aws_lambda_function.handlers["TestHandler"].vpc_config[0].security_group_ids, "sg-67890")
    error_message = "Security group ID does not match expected value"
  }

  assert {
    condition     = contains(aws_lambda_function.handlers["TestHandler"].vpc_config[0].security_group_ids, "sg-4567")
    error_message = "Security group ID does not match expected value"
  }
}

run "lambda_role_vpc_attachment" {
  assert {
    condition     = aws_iam_role_policy_attachment.vpc_execution_role[0].policy_arn == "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
    error_message = "lambda VPC policy attachment missing"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.vpc_execution_role[0].role == aws_iam_role.lambda_role[0].name
    error_message = "lambda VPC policy attachment missing"
  }
}
