locals {
  # Version of ssosync to use
  version = var.ssosync_version
  enabled = module.this.enabled

  # SSM Parameter Store is the source of truth for sensitive values.
  # Terraform reads these at apply time to populate Secrets Manager.
  # At Lambda runtime, ssosync v2.0+ reads config from Secrets Manager
  # using unprefixed env vars as secret names (configLambda() code path).
  google_credentials         = one(data.aws_ssm_parameter.google_credentials[*].value)
  scim_endpoint_url          = one(data.aws_ssm_parameter.scim_endpoint_url[*].value)
  scim_endpoint_access_token = one(data.aws_ssm_parameter.scim_endpoint_access_token[*].value)
  identity_store_id          = one(data.aws_ssm_parameter.identity_store_id[*].value)

  secrets = local.enabled ? {
    "${var.google_credentials_ssm_path}/google_credentials" = local.google_credentials
    "${var.google_credentials_ssm_path}/google_admin"       = var.google_admin_email
    "${var.google_credentials_ssm_path}/scim_endpoint"      = local.scim_endpoint_url
    "${var.google_credentials_ssm_path}/scim_access_token"  = local.scim_endpoint_access_token
    "${var.google_credentials_ssm_path}/identity_store_id"  = local.identity_store_id
    "${var.google_credentials_ssm_path}/region"             = var.region
  } : {}

  # ssosync v2.0+ dropped the Lambda_ prefix from release asset filenames.
  ssosync_artifact_url = "${var.ssosync_url_prefix}/${local.version}/ssosync_Linux_${var.architecture}.tar.gz"
  download_artifact    = "ssosync.tar.gz"

  lambda_files     = fileset("${path.module}/dist", "*")
  tar_file         = fileset(path.module, local.download_artifact)
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


// This module is the resource that actually downloads the artifact from GitHub as a tar.gz
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

}

// This resource is in charge of "notifying" when the dist folder has changed
// by updating the `keepers` value.
resource "random_pet" "zip_recreator" {
  count = local.enabled ? 1 : 0

  prefix = coalesce(module.this.name, "dist")
  keepers = {
    file_content = join(",", local.file_content_map)
  }
}

// Here we extract the downloaded tar.gz artifact
// into the `dist` directory, populating it.
resource "null_resource" "extract_my_tgz" {
  count = local.enabled ? 1 : 0

  provisioner "local-exec" {
    # ssosync v2.0+ names the binary "ssosync"; provided.al2023 requires "bootstrap".
    command = "tar -xzf ${local.download_artifact} -C dist && mv dist/ssosync dist/bootstrap"
  }
  // We want to re-extract the tar.gz when the tar.gz changes or the dist folder changes
  triggers = {
    file_content = join(",", local.file_content_map)
    tar_sha256   = join(",", local.tar_file_content)
  }

  depends_on = [module.ssosync_artifact[0]]
}

// Here we create a zip artifact from the `dist` directory, this is the artifact that will be deployed to AWS Lambda.
resource "archive_file" "lambda" {
  count = local.enabled ? 1 : 0

  type        = "zip"
  source_dir  = "dist"
  output_path = "ssosync.zip"

  // this will recreate the zip to publish to lambda when anything in the dist folder changes
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
      # ssosync v2.0+ Lambda mode (configLambda): unprefixed env vars are
      # Secrets Manager secret names, resolved at invocation time.
      GOOGLE_CREDENTIALS = "${var.google_credentials_ssm_path}/google_credentials"
      GOOGLE_ADMIN       = "${var.google_credentials_ssm_path}/google_admin"
      SCIM_ENDPOINT      = "${var.google_credentials_ssm_path}/scim_endpoint"
      SCIM_ACCESS_TOKEN  = "${var.google_credentials_ssm_path}/scim_access_token"
      IDENTITY_STORE_ID  = "${var.google_credentials_ssm_path}/identity_store_id"
      REGION             = "${var.google_credentials_ssm_path}/region"

      # Non-sensitive config: configLambda() reads these via os.LookupEnv with bare names
      # (no SSOSYNC_ prefix), bypassing Viper. Using the SSOSYNC_ prefix causes these
      # values to be silently ignored, e.g. GROUP_MATCH defaults to "*" (all groups).
      LOG_LEVEL      = var.log_level
      LOG_FORMAT     = var.log_format
      SYNC_METHOD    = var.sync_method
      USER_MATCH     = join(",", var.google_user_match)
      GROUP_MATCH    = join(",", var.google_group_match)
      IGNORE_GROUPS  = var.ignore_groups
      IGNORE_USERS   = var.ignore_users
      INCLUDE_GROUPS = var.include_groups
    }
  }

  lifecycle {
    replace_triggered_by = [archive_file.lambda]
  }
  depends_on = [null_resource.extract_my_tgz, archive_file.lambda]
}

# Secrets Manager secrets — values sourced from SSM at apply time.
# ssosync's Lambda handler resolves these by name at invocation time.
resource "aws_secretsmanager_secret" "ssosync" {
  for_each = local.secrets

  name                    = each.key
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "ssosync" {
  for_each = local.secrets

  secret_id     = aws_secretsmanager_secret.ssosync[each.key].id
  secret_string = each.value
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
