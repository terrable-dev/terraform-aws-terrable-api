mock_provider "aws" {
  source = "./tests/mocks"
}

variables {
  api_name = "test-api"
  global_policies = {
    GlobalPolicy1 = "arn:aws:iam::aws:policy/GlobalPolicy1"
    GlobalPolicy2 = "arn:aws:iam::aws:policy/GlobalPolicy2"
  }
  handlers = {
    TestHandlerOne : {
      policies = {
        HandlerOnePolicy = "arn:aws:iam::aws:policy/HandlerOne"
      }
      source = "./tests/handler.js"
      http = {
        GET = "/1"
      }
    }
    TestHandlerTwo : {
      policies = {
        HandlerTwoPolicy = "arn:aws:iam::aws:policy/HandlerTwo"
      }
      source = "./tests/handler.js"
      http = {
        GET = "/2"
      }
    }
    TestHandlerCombined : {
      policies = {
        PolicyOne = "arn:aws:iam::aws:policy/HandlerOne"
        PolicyTwo = "arn:aws:iam::aws:policy/HandlerTwo"
      }
      source = "./tests/handler.js"
      http = {
        GET = "/3"
      }
    }
  }
}

run "test_TestHandlerOne_policies" {
  assert {
    condition     = aws_iam_role_policy_attachment.handler_policies["TestHandlerOne-HandlerOnePolicy"].policy_arn == "arn:aws:iam::aws:policy/HandlerOne"
    error_message = "TestHandlerOne does not have the expected HandlerOne policy attached"
  }

  assert {
    condition     = !contains(keys(aws_iam_role_policy_attachment.handler_policies), "TestHandlerOne-HandlerTwoPolicy")
    error_message = "TestHandlerOne should not have a HandlerTwo policy attached"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.global_policies["TestHandlerOne-GlobalPolicy1-global"].policy_arn == "arn:aws:iam::aws:policy/GlobalPolicy1"
    error_message = "TestHandlerOne does not have the expected GlobalPolicy1 policy attached"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.global_policies["TestHandlerOne-GlobalPolicy2-global"].policy_arn == "arn:aws:iam::aws:policy/GlobalPolicy2"
    error_message = "TestHandlerOne does not have the expected GlobalPolicy2 policy attached"
  }
}

run "test_TestHandlerTwo_policies" {
  assert {
    condition     = aws_iam_role_policy_attachment.handler_policies["TestHandlerTwo-HandlerTwoPolicy"].policy_arn == "arn:aws:iam::aws:policy/HandlerTwo"
    error_message = "TestHandlerTwo does not have the expected HandlerTwo policy attached"
  }

  assert {
    condition     = !contains(keys(aws_iam_role_policy_attachment.handler_policies), "TestHandlerTwo-HandlerOnePolicy")
    error_message = "TestHandlerTwo should not have a HandlerOne policy attached"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.global_policies["TestHandlerTwo-GlobalPolicy1-global"].policy_arn == "arn:aws:iam::aws:policy/GlobalPolicy1"
    error_message = "TestHandlerTwo does not have the expected GlobalPolicy1 policy attached"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.global_policies["TestHandlerTwo-GlobalPolicy2-global"].policy_arn == "arn:aws:iam::aws:policy/GlobalPolicy2"
    error_message = "TestHandlerTwo does not have the expected GlobalPolicy2 policy attached"
  }
}

run "test_TestHandlerCombined_policies" {
  assert {
    condition     = aws_iam_role_policy_attachment.handler_policies["TestHandlerCombined-PolicyOne"].policy_arn == "arn:aws:iam::aws:policy/HandlerOne"
    error_message = "TestHandlerCombined does not have the expected HandlerOne policy attached"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.handler_policies["TestHandlerCombined-PolicyTwo"].policy_arn == "arn:aws:iam::aws:policy/HandlerTwo"
    error_message = "TestHandlerCombined does not have the expected HandlerTwo policy attached"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.global_policies["TestHandlerCombined-GlobalPolicy1-global"].policy_arn == "arn:aws:iam::aws:policy/GlobalPolicy1"
    error_message = "TestHandlerCombined does not have the expected GlobalPolicy1 policy attached"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.global_policies["TestHandlerCombined-GlobalPolicy2-global"].policy_arn == "arn:aws:iam::aws:policy/GlobalPolicy2"
    error_message = "TestHandlerCombined does not have the expected GlobalPolicy2 policy attached"
  }
}
