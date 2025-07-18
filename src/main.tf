locals {
  # Version of ssosync to use
  # We forked it because we use SSM Parameters to load the env vars
  # The issue has been tracked several places but never merged.
  # https://github.com/awslabs/ssosync/issues/93
  # https://github.com/awslabs/ssosync/issues/180
  version = var.ssosync_version
  # -----------------------------------------------------------
  enabled                    = module.this.enabled
  google_credentials         = one(data.aws_ssm_parameter.google_credentials[*].value)
  scim_endpoint_url          = one(data.aws_ssm_parameter.scim_endpoint_url[*].value)
  scim_endpoint_access_token = one(data.aws_ssm_parameter.scim_endpoint_access_token[*].value)
  identity_store_id          = one(data.aws_ssm_parameter.identity_store_id[*].value)

  ssosync_artifact_url = "${var.ssosync_url_prefix}/${local.version}/Lambda_ssosync_Linux_${var.architecture}.tar.gz"
  download_artifact    = "ssosync.tar.gz"

  lambda_files     = fileset("${path.module}/dist", "*")
  tar_file         = fileset("${path.module}", "${local.download_artifact}")
  tar_file_content = [for f in local.tar_file : filebase64sha256("${path.module}/${f}")]

  file_content_map = local.enabled ? [
    for f in local.lambda_files : filebase64sha256("${path.module}/dist/${f}")
  ] : []
}

data "aws_ssm_parameter" "google_credentials" {
  count = local.enabled ? 1 : 0
  name  = "${var.google_credentials_ssm_path}/google_credentials"
}

data "aws_ssm_parameter" "scim_endpoint_url" {
  count = local.enabled ? 1 : 0
  name  = "${var.google_credentials_ssm_path}/scim_endpoint_url"
}

data "aws_ssm_parameter" "scim_endpoint_access_token" {
  count = local.enabled ? 1 : 0
  name  = "${var.google_credentials_ssm_path}/scim_endpoint_access_token"
}

data "aws_ssm_parameter" "identity_store_id" {
  count = local.enabled ? 1 : 0
  name  = "${var.google_credentials_ssm_path}/identity_store_id"
}


module "ssosync_artifact" {
  count = local.enabled ? 1 : 0

  source  = "cloudposse/module-artifact/external"
  version = "0.8.0"

  filename       = local.download_artifact
  module_name    = "ssosync"
  module_path    = path.module
  url            = local.ssosync_artifact_url
  curl_arguments = ["-fsSL"]

  context = module.this.context

  depends_on = [random_pet.zip_recreator]
}

resource "random_pet" "zip_recreator" {
  count = local.enabled ? 1 : 0

  prefix = coalesce(module.this.name, "dist")
  keepers = {
    file_content = join(",", local.file_content_map)
  }
}

resource "null_resource" "extract_my_tgz" {
  count = local.enabled ? 1 : 0

  provisioner "local-exec" {
    command = "tar -xzf ${local.download_artifact} -C dist && chmod +x dist/ssosync"
  }
  triggers = {
    file_content = join(",", local.file_content_map)
    tar_sha256   = join(",", local.tar_file_content)
  }

  depends_on = [module.ssosync_artifact[0]]
}

resource "archive_file" "lambda" {
  count = local.enabled ? 1 : 0

  type        = "zip"
  source_dir  = "dist"
  output_path = "ssosync.zip"

  lifecycle {
    replace_triggered_by = [random_pet.zip_recreator]
  }

  depends_on = [null_resource.extract_my_tgz]
}


resource "aws_lambda_function" "ssosync" {
  count = local.enabled ? 1 : 0

  function_name    = module.this.id
  filename         = "ssosync.zip"
  source_code_hash = module.ssosync_artifact[0].base64sha256
  description      = "Syncs Google Workspace users and groups to AWS SSO"
  role             = aws_iam_role.default[0].arn
  # While yes, we ultimately have a go binary we are executing. Downloading the Tar, extracting, 
  # and moving the binary to be called "bootstrap" is not a fun thing to execute in Terraform with state.
  handler     = "bootstrap"
  runtime     = "provided.al2023"
  timeout     = 900
  memory_size = 128

  environment {
    variables = {
      SSOSYNC_LOG_LEVEL               = var.log_level
      SSOSYNC_LOG_FORMAT              = var.log_format
      SSOSYNC_GOOGLE_CREDENTIALS_JSON = local.google_credentials
      SSOSYNC_GOOGLE_ADMIN            = var.google_admin_email
      SSOSYNC_SCIM_ENDPOINT           = local.scim_endpoint_url
      SSOSYNC_SCIM_ACCESS_TOKEN       = local.scim_endpoint_access_token
      SSOSYNC_REGION                  = var.region
      SSOSYNC_IDENTITY_STORE_ID       = local.identity_store_id
      SSOSYNC_USER_MATCH              = join(",", var.google_user_match)
      SSOSYNC_GROUP_MATCH             = join(",", var.google_group_match)
      SSOSYNC_SYNC_METHOD             = var.sync_method
      SSOSYNC_IGNORE_GROUPS           = var.ignore_groups
      SSOSYNC_IGNORE_USERS            = var.ignore_users
      SSOSYNC_INCLUDE_GROUPS          = var.include_groups
      SSOSYNC_LOAD_ASM_SECRETS        = false
    }
  }

  lifecycle {
    replace_triggered_by = [archive_file.lambda]
  }
  depends_on = [null_resource.extract_my_tgz, archive_file.lambda]
}

resource "aws_cloudwatch_event_rule" "ssosync" {
  count = var.enabled ? 1 : 0

  name                = module.this.id
  description         = "Run ssosync on a schedule"
  schedule_expression = var.schedule_expression

}

resource "aws_cloudwatch_event_target" "ssosync" {
  count = var.enabled ? 1 : 0

  rule      = aws_cloudwatch_event_rule.ssosync[0].name
  target_id = module.this.id
  arn       = aws_lambda_function.ssosync[0].arn
}


resource "aws_lambda_permission" "allow_cloudwatch_execution" {
  count = local.enabled ? 1 : 0

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ssosync[0].arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ssosync[0].arn
}
