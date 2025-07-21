# ssosync 🌐

**Sync Google Workspace users and groups to AWS IAM Identity Center (SSO) via CLI or Lambda, now fully configurable via environment variables.**

This is intended to be used with CloudPosse's [aws-ssosync](https://github.com/cloudposse-terraform-components/aws-ssosync) component.

---

## 🚀 Features

- Fetches users and groups from Google Workspace using Admin SDK.
- Provisions, updates, and removes identities in AWS Identity Center using SCIM API.
- Configurable entirely via environment variables—ideal for Terraform, Kubernetes, or AWS Lambda.

---

## 🔧 Why This Fork?

The original `ssosync` required AWS Secrets Manager for sensitive parameters like SCIM tokens. Our fork removes that limitation. Now you can:

- Use any secret source supported by your Terraform provider.
- Inject values via environment variables: no more hardcoding or AWS Secrets dependency.
- Maintain portability across deployment platforms.

---

## 📌 Configuration

All settings are configurable via env vars (or CLI flags):

| Env Variable                                                                                     | Description                         |
| ------------------------------------------------------------------------------------------------ | ----------------------------------- |
| `GOOGLE_CREDENTIALS`                                                                             | Path to Google service‑account JSON |
| `GOOGLE_ADMIN`                                                                                   | Workspace admin email               |
| `SCIM_ENDPOINT`                                                                                  | AWS SSO SCIM endpoint URL           |
| `SCIM_ACCESS_TOKEN`                                                                              | AWS SSO SCIM access token           |
| Optional filters: `USER_MATCH`, `GROUP_MATCH`, `IGNORE_USERS`, `IGNORE_GROUPS`, `INCLUDE_GROUPS` |                                     |
| Sync mode: `SYNC_METHOD` (`groups` or `users_groups`)                                            |                                     |
| Logging options: `LOG_LEVEL`, `LOG_FORMAT`                                                       |                                     |

These map exactly to the fork’s CLI flags, e.g.:

```bash
export GOOGLE_CREDENTIALS="/secrets/google-creds.json"
export GOOGLE_ADMIN="admin@example.com"
export SCIM_ENDPOINT="https://portal.sso.us-west-2.amazonaws.com/scim/v2"
export SCIM_ACCESS_TOKEN="xxxx"
export SYNC_METHOD="groups"
export GROUP_MATCH="name:Dev*"
```

---

## ⚙️ Installation

1. Clone this repo:

   ```bash
   git clone https://github.com/Benbentwo/ssosync.git
   cd ssosync
   ```

2. Build the Go binary:

   ```bash
   make go-build
   ```

3. Or deploy the `./ssosync` binary directly in your environment or Lambda.

---

## 💻 Local Usage

```bash
./ssosync \
  --google-credentials "$GOOGLE_CREDENTIALS" \
  --google-admin "$GOOGLE_ADMIN" \
  --endpoint "$SCIM_ENDPOINT" \
  --access-token "$SCIM_ACCESS_TOKEN" \
  --sync-method "$SYNC_METHOD" \
  --group-match "$GROUP_MATCH" \
  --log-level info
```

Environment variables automatically provide defaults for flags.

---

## ☁️ AWS Lambda Deployment

Package the binary and deploy using your preferred IaC:

- **ZIP or containerize** `ssosync`.
- Set the above env vars in Lambda configuration (via Terraform, CloudFormation, or console).
- Schedule the function on a CRON trigger via EventBridge (CloudWatch Events) for periodic syncing.

---

## 📚 References

This fork is built on top of the original `awslabs/ssosync` project ([github.com][1], [github.com][2], [github.com][3])—all major capabilities remain intact, with the improved configuration layer front and center.

---

## 🛠️ Contributing

Please file issues or PRs if you encounter bugs or want new features. We welcome help with:

- More flexible secret backends (e.g., Kubernetes Secrets, HashiCorp Vault).
- Enhanced filtering options.
- Improved test coverage.

---

## ⚖️ License

Apache 2.0. See [LICENSE](LICENSE).

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | >= 2.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0, < 6.0.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 1.4.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | >= 2.3.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0, < 6.0.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 1.4.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_iam_roles"></a> [iam\_roles](#module\_iam\_roles) | ../account-map/modules/iam-roles | n/a |
| <a name="module_ssosync_artifact"></a> [ssosync\_artifact](#module\_ssosync\_artifact) | cloudposse/module-artifact/external | 0.8.0 |
| <a name="module_this"></a> [this](#module\_this) | cloudposse/label/null | 0.25.0 |

## Resources

| Name | Type |
|------|------|
| [archive_file.lambda](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/resources/file) | resource |
| [aws_cloudwatch_event_rule.ssosync](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.ssosync](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_iam_role.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_lambda_function.ssosync](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.allow_cloudwatch_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [null_resource.extract_my_tgz](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_pet.zip_recreator](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [aws_iam_policy_document.ssosync_lambda_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ssosync_lambda_identity_center](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_ssm_parameter.google_credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.identity_store_id](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.scim_endpoint_access_token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.scim_endpoint_url](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br/>This is for some rare cases where resources want additional configuration of tags<br/>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_architecture"></a> [architecture](#input\_architecture) | Architecture of the Lambda function | `string` | `"x86_64"` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br/>in the order they appear in the list. New attributes are appended to the<br/>end of the list. The elements of the list are joined by the `delimiter`<br/>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br/>  "additional_tag_map": {},<br/>  "attributes": [],<br/>  "delimiter": null,<br/>  "descriptor_formats": {},<br/>  "enabled": true,<br/>  "environment": null,<br/>  "id_length_limit": null,<br/>  "label_key_case": null,<br/>  "label_order": [],<br/>  "label_value_case": null,<br/>  "labels_as_tags": [<br/>    "unset"<br/>  ],<br/>  "name": null,<br/>  "namespace": null,<br/>  "regex_replace_chars": null,<br/>  "stage": null,<br/>  "tags": {},<br/>  "tenant": null<br/>}</pre> | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br/>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>  format = string<br/>  labels = list(string)<br/>}`<br/>(Type is `any` so the map values can later be enhanced to provide additional options.)<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used for region e.g. 'uw2', 'us-west-2', OR role 'prod', 'staging', 'dev', 'UAT' | `string` | `null` | no |
| <a name="input_google_admin_email"></a> [google\_admin\_email](#input\_google\_admin\_email) | Google Admin email | `string` | n/a | yes |
| <a name="input_google_credentials_ssm_path"></a> [google\_credentials\_ssm\_path](#input\_google\_credentials\_ssm\_path) | SSM Path for `ssosync` secrets | `string` | `"/ssosync"` | no |
| <a name="input_google_group_match"></a> [google\_group\_match](#input\_google\_group\_match) | Google Workspace group filter query parameter, example: 'name:Admin* email:aws-*', see: https://developers.google.com/admin-sdk/directory/v1/guides/search-groups | `list(string)` | `[]` | no |
| <a name="input_google_user_match"></a> [google\_user\_match](#input\_google\_user\_match) | Google Workspace user filter query parameter, example: 'name:John* email:admin*', see: https://developers.google.com/admin-sdk/directory/v1/guides/search-users | `list(string)` | `[]` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_ignore_groups"></a> [ignore\_groups](#input\_ignore\_groups) | Ignore these Google Workspace groups | `string` | `""` | no |
| <a name="input_ignore_users"></a> [ignore\_users](#input\_ignore\_users) | Ignore these Google Workspace users | `string` | `""` | no |
| <a name="input_include_groups"></a> [include\_groups](#input\_include\_groups) | Include only these Google Workspace groups. (Only applicable for sync\_method user\_groups) | `string` | `""` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>**Notes:**<br/>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br/>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br/>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_log_format"></a> [log\_format](#input\_log\_format) | Log format for Lambda function logging | `string` | `"json"` | no |
| <a name="input_log_level"></a> [log\_level](#input\_log\_level) | Log level for Lambda function logging | `string` | `"warn"` | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | ID element. Usually an abbreviation of your organization name, e.g. 'eg' or 'cp', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region where AWS SSO is enabled | `string` | n/a | yes |
| <a name="input_schedule_expression"></a> [schedule\_expression](#input\_schedule\_expression) | Schedule for trigger the execution of ssosync (see CloudWatch schedule expressions) | `string` | `"rate(15 minutes)"` | no |
| <a name="input_ssosync_url_prefix"></a> [ssosync\_url\_prefix](#input\_ssosync\_url\_prefix) | URL prefix for ssosync binary | `string` | `"https://github.com/cloudposse/ssosync/releases/download"` | no |
| <a name="input_ssosync_version"></a> [ssosync\_version](#input\_ssosync\_version) | Version of ssosync to use | `string` | `"v3.0.0"` | no |
| <a name="input_stage"></a> [stage](#input\_stage) | ID element. Usually used to indicate role, e.g. 'prod', 'staging', 'source', 'build', 'test', 'deploy', 'release' | `string` | `null` | no |
| <a name="input_sync_method"></a> [sync\_method](#input\_sync\_method) | Sync method to use | `string` | `"groups"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | ID element \_(Rarely used, not included by default)\_. A customer identifier, indicating who this instance of a resource is for | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | ARN of the lambda function |
| <a name="output_invoke_arn"></a> [invoke\_arn](#output\_invoke\_arn) | Invoke ARN of the lambda function |
| <a name="output_qualified_arn"></a> [qualified\_arn](#output\_qualified\_arn) | ARN identifying your Lambda Function Version (if versioning is enabled via publish = true) |
| <a name="output_ssosync_artifact_url"></a> [ssosync\_artifact\_url](#output\_ssosync\_artifact\_url) | URL of the ssosync artifact |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->