mock_provider "aws" {
  source = "./tests/mocks"
}

variables {
  api_name = "test-api"
  rest_api = {
    endpoint_type    = "PRIVATE"
    vpc_endpoint_ids = ["vpce-testvpce1", "vpce-testvpce2"]
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

run "vpc_endpoint_ids_set" {
  assert {
    condition     = contains(resource.aws_api_gateway_rest_api.api_gateway[0].endpoint_configuration[0].vpc_endpoint_ids, "vpce-testvpce1")
    error_message = "API Gateway VPC endpoint IDs should contain vpce-testvpce1"
  }

  assert {
    condition     = contains(resource.aws_api_gateway_rest_api.api_gateway[0].endpoint_configuration[0].vpc_endpoint_ids, "vpce-testvpce2")
    error_message = "API Gateway VPC endpoint IDs should contain vpce-testvpce2"
  }

  assert {
    condition     = length(resource.aws_api_gateway_rest_api.api_gateway[0].endpoint_configuration[0].vpc_endpoint_ids) == 2
    error_message = "API Gateway should have all specified VPCEs assigned"
  }
}

run "resource_policy_set" {
  assert {
    condition     = length(jsondecode(resource.aws_iam_policy.api_policy[0].policy).Statement[0].Condition.StringLike["aws:SourceVpce"]) == 2
    error_message = "Policy should include all specified VPCEs"
  }

  assert {
    condition     = contains(jsondecode(resource.aws_iam_policy.api_policy[0].policy).Statement[0].Condition.StringLike["aws:SourceVpce"], "vpce-testvpce1")
    error_message = "Policy should include vpce-testvpce1"
  }

  assert {
    condition     = contains(jsondecode(resource.aws_iam_policy.api_policy[0].policy).Statement[0].Condition.StringLike["aws:SourceVpce"], "vpce-testvpce2")
    error_message = "Policy should include vpce-testvpce2"
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