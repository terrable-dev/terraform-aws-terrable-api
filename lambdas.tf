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

resource "aws_lambda_function" "handlers" {
  for_each         = local.handlers
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
