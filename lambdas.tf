data "node-lambda-packager_package" "handlers" {
  for_each = local.handlers

  args = [
    "--bundle",
    "--external:@aws-sdk*",
    "--platform=node",
    "--target=es2021",
  ]

  entrypoint        = "${path.root}//${each.value.source}"
  working_directory = ""
}

locals {
  # Collect all SSM parameters (including global ones)
  ssm_params = merge(
    {
      for k, v in try(var.environment_variables, {}) :
      k => trimprefix(v, "SSM:") if can(regex("^SSM:", v))
    },
  )


  base_handlers = {
    for handler_name, handler in var.handlers : handler_name => {
      name    = handler_name
      source  = handler.source
      runtime = coalesce(handler.runtime, var.runtime)
      http    = try(handler.http, null)
      timeout = coalesce(handler.timeout, var.timeout)
      environment_variables = {
        for k, v in try(var.environment_variables, {}) :
        k => (
          can(regex("^SSM:", v)) ?
          data.aws_ssm_parameter.env_vars[k].value :
          v
        )
      }
      tags     = handler.tags != null ? handler.tags : {}
      policies = handler.policies
    }
  }
}

data "aws_ssm_parameter" "env_vars" {
  for_each = local.ssm_params
  name     = each.value
}

resource "aws_lambda_function" "handlers" {
  for_each         = local.base_handlers
  filename         = data.node-lambda-packager_package.handlers[each.key].filename
  function_name    = "${var.api_name}-${each.value.name}"
  source_code_hash = data.node-lambda-packager_package.handlers[each.key].source_code_hash
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = each.value.runtime
  timeout          = each.value.timeout

  environment {
    variables = each.value.environment_variables
  }

  vpc_config {
    subnet_ids         = try(var.vpc.subnet_ids, [])
    security_group_ids = try(var.vpc.security_group_ids, [])
  }

  tags = merge(each.value.tags)

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_iam_role_policy_attachment.vpc_execution_role,
  ]
}

resource "aws_cloudwatch_log_group" "lambda_log_groups" {
  for_each = local.handlers

  name              = "/aws/lambda/${aws_lambda_function.handlers[each.key].function_name}"
  retention_in_days = var.log_retention_days
}
