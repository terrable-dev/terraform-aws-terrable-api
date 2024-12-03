data "node-lambda-packager_package" "handlers" {
  for_each = local.handlers

  args = [
    "--bundle",
    "--external:@aws-sdk*",
    "--platform=node",
    "--target=es2021",
    "--outdir=dist",
  ]

  entrypoint        = "${path.root}/${each.value.source}"
  working_directory = "${path.root}/${dirname(each.value.source)}"
}

locals {
  base_handlers = {
    for handler_name, handler in var.handlers : handler_name => {
      name   = handler_name
      source = handler.source
      http   = try(handler.http, null)
      raw_environment_vars = merge(
        try(var.global_environment_variables, {}),
        try(handler.environment_variables, {})
      )
      tags     = handler.tags != null ? handler.tags : {}
      policies = handler.policies
    }
  }

  # Collect all SSM parameters (including global ones)
  ssm_params = merge(
    # Global SSM parameters
    {
      for k, v in try(var.global_environment_variables, {}) :
      "global-${k}" => trimprefix(v, "SSM:") if can(regex("^SSM:", v))
    },
    # Handler-specific SSM parameters
    merge([
      for handler_name, handler in local.base_handlers : {
        for k, v in handler.raw_environment_vars :
        "${handler_name}-${k}" => trimprefix(v, "SSM:") if can(regex("^SSM:", v))
      }
    ]...)
  )

  env_var_handlers = {
    for handler_name, handler in local.base_handlers : handler_name => {
      name   = handler.name
      source = handler.source
      http   = handler.http
      environment_vars = {
        for k, v in handler.raw_environment_vars :
        k => (
          can(regex("^SSM:", v)) ?
          data.aws_ssm_parameter.env_vars[
            contains(keys(local.ssm_params), "${handler_name}-${k}") ?
            "${handler_name}-${k}" : "global-${k}"
          ].value :
          v
        )
      }
      tags     = handler.tags
      policies = handler.policies
    }
  }
}

data "aws_ssm_parameter" "env_vars" {
  for_each = local.ssm_params
  name     = each.value
}

resource "aws_lambda_function" "handlers" {
  for_each         = local.env_var_handlers
  filename         = data.node-lambda-packager_package.handlers[each.key].filename
  function_name    = "${var.api_name}-${each.value.name}"
  source_code_hash = data.node-lambda-packager_package.handlers[each.key].source_code_hash
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"

  environment {
    variables = each.value.environment_vars
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