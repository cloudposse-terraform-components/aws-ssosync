

<!-- markdownlint-disable -->
<a href="https://cpco.io/homepage"><img src="https://github.com/cloudposse-terraform-components/aws-ssosync/blob/main/.github/banner.png?raw=true" alt="Project Banner"/></a><br/>
    <p align="right">
<a href="https://github.com/cloudposse-terraform-components/aws-ssosync/releases/latest"><img src="https://img.shields.io/github/release/cloudposse-terraform-components/aws-ssosync.svg?style=for-the-badge" alt="Latest Release"/></a><a href="https://slack.cloudposse.com"><img src="https://slack.cloudposse.com/for-the-badge.svg" alt="Slack Community"/></a></p>
<!-- markdownlint-restore -->

<!--




  ** DO NOT EDIT THIS FILE
  **
  ** This file was automatically generated by the `cloudposse/build-harness`.
  ** 1) Make all changes to `README.yaml`
  ** 2) Run `make init` (you only need to do this once)
  ** 3) Run`make readme` to rebuild this file.
  **
  ** (We maintain HUNDREDS of open source projects. This is how we maintain our sanity.)
  **





-->

Deploys [AWS ssosync](https://github.com/awslabs/ssosync) to sync Google Groups with AWS SSO.

AWS `ssosync` is a Lambda application that regularly manages Identity Store users.

This component requires manual deployment by a privileged user because it deploys a role in the root or identity
management account.

## Usage

You should be able to deploy the `aws-ssosync` component to the same account as `aws-sso`. Typically that is the
`core-gbl-root` or `gbl-root` stack.

**Stack Level**: Global **Deployment**: Must be deployed by `managers` or SuperAdmin using `atmos` CLI

The following is an example snippet for how to use this component:

(`stacks/catalog/aws-ssosync.yaml`)

```yaml
components:
  terraform:
    aws-ssosync:
      vars:
        enabled: true
        name: aws-ssosync
        google_admin_email: an-actual-admin@acme.com
        ssosync_url_prefix: "https://github.com/Benbentwo/ssosync/releases/download"
        ssosync_version: "2.0.2"
        google_credentials_ssm_path: "/ssosync"
        log_format: text
        log_level: debug
        schedule_expression: "rate(15 minutes)"
```

We recommend following a similar process to what the [AWS ssosync](https://github.com/awslabs/ssosync) documentation
recommends.

### Deployment

Overview of steps:

1. Configure AWS IAM Identity Center
1. Configure Google Cloud console
1. Configure Google Admin console
1. Deploy the `aws-ssosync` component
1. Deploy the `aws-sso` component

#### 1. Configure AWS IAM Identity Center (AWS SSO)

Follow
[AWS documentation to configure SAML and SCIM with Google Workspace and IAM Identity Center](https://docs.aws.amazon.com/singlesignon/latest/userguide/gs-gwp.html).

As part of this process, save the SCIM endpoint token and URL. Then in AWS SSM Parameter Store, create two
`SecureString` parameters in the same account used for AWS SSO. This is usually the root account in the primary region.

```
/ssosync/scim_endpoint_access_token
/ssosync/scim_endpoint_url
```

One more parameter you'll need is your Identity Store ID. To obtain your Identity Store ID, go to the AWS Identity
Center console and select `Settings`. Under the `Identity Source` section, copy the Identity Store ID. In the same
account used for AWS SSO, create the following parameter:

```
/ssosync/identity_store_id
```

#### 2. Configure Google Cloud console

Within the Google Cloud console, we need to create a new Google Project and Service Account and enable the Admin SDK
API. Follow these steps:


2. Create a new project. Give the project a descriptive name such as `AWS SSO Sync`
3. Enable Admin SDK in APIs: `APIs & Services > Enabled APIs & Services > + ENABLE APIS AND SERVICES`

![Enable Admin SDK](https://raw.githubusercontent.com/cloudposse/terraform-aws-components/main/modules/aws-ssosync/docs/img/admin_sdk.png) #
use raw URL so that this works in both GitHub and docusaurus

4. Create Service Account: `IAM & Admin > Service Accounts > Create Service Account`
  [(ref)](https://cloud.google.com/iam/docs/service-accounts-create).

![Create Service Account](https://raw.githubusercontent.com/cloudposse/terraform-aws-components/main/modules/aws-ssosync/docs/img/create_service_account.png) #
use raw URL so that this works in both GitHub and docusaurus

5. Download credentials for the new Service Account:
  `IAM & Admin > Service Accounts > select Service Account > Keys > ADD KEY > Create new key > JSON`

![Download Credentials](https://raw.githubusercontent.com/cloudposse/terraform-aws-components/main/modules/aws-ssosync/docs/img/dl_service_account_creds.png) #
use raw URL so that this works in both GitHub and docusaurus

6. Save the JSON credentials as a new `SecureString` AWS SSM parameter in the same account used for AWS SSO. Use the
  full JSON string as the value for the parameter.

```
/ssosync/google_credentials
```

#### 3. Configure Google Admin console

- Open the Google Admin console
- From your domain’s Admin console, go to `Main menu menu > Security > Access and data control > API controls`
  [(ref)](https://developers.google.com/cloud-search/docs/guides/delegation)
- In the Domain wide delegation pane, select `Manage Domain Wide Delegation`.
- Click `Add new`.
- In the Client ID field, enter the client ID obtained from the service account creation steps above.
- In the OAuth Scopes field, enter a comma-delimited list of the scopes required for your application. Use the scope
  `https://www.googleapis.com/auth/cloud_search.query` for search applications using the Query API.
- Add the following permission: [(ref)](https://github.com/awslabs/ssosync?tab=readme-ov-file#google)

```console
https://www.googleapis.com/auth/admin.directory.group.readonly
https://www.googleapis.com/auth/admin.directory.group.member.readonly
https://www.googleapis.com/auth/admin.directory.user.readonly
```

#### 4. Deploy the `aws-ssosync` component

Make sure that all four of the following SSM parameters exist in the target account and region:

- `/ssosync/scim_endpoint_url`
- `/ssosync/scim_endpoint_access_token`
- `/ssosync/identity_store_id`
- `/ssosync/google_credentials`

If deployed successfully, Groups and Users should be programmatically copied from the Google Workspace into AWS IAM
Identity Center on the given schedule.

If these Groups are not showing up, check the CloudWatch logs for the new Lambda function and refer the [FAQs](#FAQ)
included below.

#### 5. Deploy the `aws-sso` component

Use the names of the Groups now provisioned programmatically in the `aws-sso` component catalog. Follow the
[aws-sso](../aws-sso/) component documentation to deploy the `aws-sso` component.

### FAQ

#### Why is the tool forked by `Benbentwo`?

The `awslabs` tool requires AWS Secrets Managers for the Google Credentials. However, we would prefer to use AWS SSM to
store all credentials consistency and not require AWS Secrets Manager. Therefore we've created a Pull Request and will
point to a fork until the PR is merged.

Ref:

- https://github.com/awslabs/ssosync/pull/133
- https://github.com/awslabs/ssosync/issues/93

#### What should I use for the Google Admin Email Address?

The Service Account created will assume the User given by `--google-admin` / `SSOSYNC_GOOGLE_ADMIN` /
`var.google_admin_email`. Therefore, this user email must be a valid Google admin user in your organization.

This is not the same email as the Service Account.

If Google fails to query Groups, you may see the following error:

```console
Notifying Lambda and mark this execution as Failure: googleapi: Error 404: Domain not found., notFound
```

#### Common Group Name Query Error

If filtering group names using query strings, make sure the provided string is valid. For example,
`google_group_match: "name:aws*"` is incorrect. Instead use `google_group_match: "Name:aws*"`

If not, you may again see the same error message:

```console
Notifying Lambda and mark this execution as Failure: googleapi: Error 404: Domain not found., notFound
```

Ref:

> The specific error you are seeing is because the google api doesn't like the query string you provided for the -g
> parameter. try -g "Name:Fuel\*"

https://github.com/awslabs/ssosync/issues/91

<!-- prettier-ignore-start -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | >= 2.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0, < 6.0.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | >= 2.3.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0, < 6.0.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ssosync_artifact"></a> [ssosync\_artifact](#module\_ssosync\_artifact) | cloudposse/module-artifact/external | 0.8.0 |
| <a name="module_this"></a> [this](#module\_this) | cloudposse/label/null | 0.25.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.ssosync](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.ssosync](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_iam_role.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_lambda_function.ssosync](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.allow_cloudwatch_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [null_resource.extract_my_tgz](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [archive_file.lambda](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
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
| <a name="input_google_group_match"></a> [google\_group\_match](#input\_google\_group\_match) | Google Workspace group filter query parameter, example: 'name:Admin* email:aws-*', see: https://developers.google.com/admin-sdk/directory/v1/guides/search-groups | `string` | `""` | no |
| <a name="input_google_user_match"></a> [google\_user\_match](#input\_google\_user\_match) | Google Workspace user filter query parameter, example: 'name:John* email:admin*', see: https://developers.google.com/admin-sdk/directory/v1/guides/search-users | `string` | `""` | no |
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
| <a name="input_ssosync_url_prefix"></a> [ssosync\_url\_prefix](#input\_ssosync\_url\_prefix) | URL prefix for ssosync binary | `string` | `"https://github.com/Benbentwo/ssosync/releases/download"` | no |
| <a name="input_ssosync_version"></a> [ssosync\_version](#input\_ssosync\_version) | Version of ssosync to use | `string` | `"v2.0.2"` | no |
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
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- prettier-ignore-end -->

## References

- [cloudposse/terraform-aws-components](https://github.com/cloudposse/terraform-aws-components/tree/main/modules/aws-ssosync) -
  Cloud Posse's upstream component


> [!TIP]
> #### 👽 Use Atmos with Terraform
> Cloud Posse uses [`atmos`](https://atmos.tools) to easily orchestrate multiple environments using Terraform. <br/>
> Works with [Github Actions](https://atmos.tools/integrations/github-actions/), [Atlantis](https://atmos.tools/integrations/atlantis), or [Spacelift](https://atmos.tools/integrations/spacelift).
>
> <details>
> <summary><strong>Watch demo of using Atmos with Terraform</strong></summary>
> <img src="https://github.com/cloudposse/atmos/blob/main/docs/demo.gif?raw=true"/><br/>
> <i>Example of running <a href="https://atmos.tools"><code>atmos</code></a> to manage infrastructure from our <a href="https://atmos.tools/quick-start/">Quick Start</a> tutorial.</i>
> </details>











## Related Projects

Check out these related projects.

- [Cloud Posse Terraform Modules](https://docs.cloudposse.com/modules/) - Our collection of reusable Terraform modules used by our reference architectures.
- [Atmos](https://atmos.tools) - Atmos is like docker-compose but for your infrastructure


> [!TIP]
> #### Use Terraform Reference Architectures for AWS
>
> Use Cloud Posse's ready-to-go [terraform architecture blueprints](https://cloudposse.com/reference-architecture/) for AWS to get up and running quickly.
>
> ✅ We build it together with your team.<br/>
> ✅ Your team owns everything.<br/>
> ✅ 100% Open Source and backed by fanatical support.<br/>
>
> <a href="https://cpco.io/commercial-support?utm_source=github&utm_medium=readme&utm_campaign=cloudposse-terraform-components/aws-ssosync&utm_content=commercial_support"><img alt="Request Quote" src="https://img.shields.io/badge/request%20quote-success.svg?style=for-the-badge"/></a>
> <details><summary>📚 <strong>Learn More</strong></summary>
>
> <br/>
>
> Cloud Posse is the leading [**DevOps Accelerator**](https://cpco.io/commercial-support?utm_source=github&utm_medium=readme&utm_campaign=cloudposse-terraform-components/aws-ssosync&utm_content=commercial_support) for funded startups and enterprises.
>
> *Your team can operate like a pro today.*
>
> Ensure that your team succeeds by using Cloud Posse's proven process and turnkey blueprints. Plus, we stick around until you succeed.
> #### Day-0:  Your Foundation for Success
> - **Reference Architecture.** You'll get everything you need from the ground up built using 100% infrastructure as code.
> - **Deployment Strategy.** Adopt a proven deployment strategy with GitHub Actions, enabling automated, repeatable, and reliable software releases.
> - **Site Reliability Engineering.** Gain total visibility into your applications and services with Datadog, ensuring high availability and performance.
> - **Security Baseline.** Establish a secure environment from the start, with built-in governance, accountability, and comprehensive audit logs, safeguarding your operations.
> - **GitOps.** Empower your team to manage infrastructure changes confidently and efficiently through Pull Requests, leveraging the full power of GitHub Actions.
>
> <a href="https://cpco.io/commercial-support?utm_source=github&utm_medium=readme&utm_campaign=cloudposse-terraform-components/aws-ssosync&utm_content=commercial_support"><img alt="Request Quote" src="https://img.shields.io/badge/request%20quote-success.svg?style=for-the-badge"/></a>
>
> #### Day-2: Your Operational Mastery
> - **Training.** Equip your team with the knowledge and skills to confidently manage the infrastructure, ensuring long-term success and self-sufficiency.
> - **Support.** Benefit from a seamless communication over Slack with our experts, ensuring you have the support you need, whenever you need it.
> - **Troubleshooting.** Access expert assistance to quickly resolve any operational challenges, minimizing downtime and maintaining business continuity.
> - **Code Reviews.** Enhance your team’s code quality with our expert feedback, fostering continuous improvement and collaboration.
> - **Bug Fixes.** Rely on our team to troubleshoot and resolve any issues, ensuring your systems run smoothly.
> - **Migration Assistance.** Accelerate your migration process with our dedicated support, minimizing disruption and speeding up time-to-value.
> - **Customer Workshops.** Engage with our team in weekly workshops, gaining insights and strategies to continuously improve and innovate.
>
> <a href="https://cpco.io/commercial-support?utm_source=github&utm_medium=readme&utm_campaign=cloudposse-terraform-components/aws-ssosync&utm_content=commercial_support"><img alt="Request Quote" src="https://img.shields.io/badge/request%20quote-success.svg?style=for-the-badge"/></a>
> </details>

## ✨ Contributing

This project is under active development, and we encourage contributions from our community.



Many thanks to our outstanding contributors:

<a href="https://github.com/cloudposse-terraform-components/aws-ssosync/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=cloudposse-terraform-components/aws-ssosync&max=24" />
</a>

For 🐛 bug reports & feature requests, please use the [issue tracker](https://github.com/cloudposse-terraform-components/aws-ssosync/issues).

In general, PRs are welcome. We follow the typical "fork-and-pull" Git workflow.
 1. Review our [Code of Conduct](https://github.com/cloudposse-terraform-components/aws-ssosync/?tab=coc-ov-file#code-of-conduct) and [Contributor Guidelines](https://github.com/cloudposse/.github/blob/main/CONTRIBUTING.md).
 2. **Fork** the repo on GitHub
 3. **Clone** the project to your own machine
 4. **Commit** changes to your own branch
 5. **Push** your work back up to your fork
 6. Submit a **Pull Request** so that we can review your changes

**NOTE:** Be sure to merge the latest changes from "upstream" before making a pull request!

### 🌎 Slack Community

Join our [Open Source Community](https://cpco.io/slack?utm_source=github&utm_medium=readme&utm_campaign=cloudposse-terraform-components/aws-ssosync&utm_content=slack) on Slack. It's **FREE** for everyone! Our "SweetOps" community is where you get to talk with others who share a similar vision for how to rollout and manage infrastructure. This is the best place to talk shop, ask questions, solicit feedback, and work together as a community to build totally *sweet* infrastructure.

### 📰 Newsletter

Sign up for [our newsletter](https://cpco.io/newsletter?utm_source=github&utm_medium=readme&utm_campaign=cloudposse-terraform-components/aws-ssosync&utm_content=newsletter) and join 3,000+ DevOps engineers, CTOs, and founders who get insider access to the latest DevOps trends, so you can always stay in the know.
Dropped straight into your Inbox every week — and usually a 5-minute read.

### 📆 Office Hours <a href="https://cloudposse.com/office-hours?utm_source=github&utm_medium=readme&utm_campaign=cloudposse-terraform-components/aws-ssosync&utm_content=office_hours"><img src="https://img.cloudposse.com/fit-in/200x200/https://cloudposse.com/wp-content/uploads/2019/08/Powered-by-Zoom.png" align="right" /></a>

[Join us every Wednesday via Zoom](https://cloudposse.com/office-hours?utm_source=github&utm_medium=readme&utm_campaign=cloudposse-terraform-components/aws-ssosync&utm_content=office_hours) for your weekly dose of insider DevOps trends, AWS news and Terraform insights, all sourced from our SweetOps community, plus a _live Q&A_ that you can’t find anywhere else.
It's **FREE** for everyone!
## License

<a href="https://opensource.org/licenses/Apache-2.0"><img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=for-the-badge" alt="License"></a>

<details>
<summary>Preamble to the Apache License, Version 2.0</summary>
<br/>
<br/>



```text
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

  https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
```
</details>

## Trademarks

All other trademarks referenced herein are the property of their respective owners.


---
Copyright © 2017-2025 [Cloud Posse, LLC](https://cpco.io/copyright)


<a href="https://cloudposse.com/readme/footer/link?utm_source=github&utm_medium=readme&utm_campaign=cloudposse-terraform-components/aws-ssosync&utm_content=readme_footer_link"><img alt="README footer" src="https://cloudposse.com/readme/footer/img"/></a>

<img alt="Beacon" width="0" src="https://ga-beacon.cloudposse.com/UA-76589703-4/cloudposse-terraform-components/aws-ssosync?pixel&cs=github&cm=readme&an=aws-ssosync"/>
