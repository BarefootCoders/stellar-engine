# Workflows Module
Simple module for creating a workflow encryped by a CMEK. 

Takes in a file path to a yaml file for the workflow source code.

<!-- BEGIN TOC -->
- [Example Usage](#example-usage)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Example Usage

```hcl
module "workflows" {
  source = "../../../modules/workflows"
  project = var.project
  name = "example-workflow"
  region = var.region
  logging_level = var.logging_level
  env_vars = var.env_vars
  key = var.key
  file = var.file
}
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [file](variables.tf#L13) | File path to the instructions for the workflow. | <code>string</code> | ✓ |  |
| [key](variables.tf#L18) | The CMEK used to encrypt the workflow. | <code>string</code> | ✓ |  |
| [name](variables.tf#L29) | Name of the workflow. | <code>string</code> | ✓ |  |
| [project](variables.tf#L34) | The Google Project ID. | <code>string</code> | ✓ |  |
| [region](variables.tf#L39) | The Google Cloud region. | <code>string</code> | ✓ |  |
| [description](variables.tf#L1) | Description of the workflow. | <code>string</code> |  | <code>null</code> |
| [env_vars](variables.tf#L7) | Environment variables made available to your workflow execution. | <code>map&#40;string&#41;</code> |  | <code>null</code> |
| [logging_level](variables.tf#L23) | Logging level of workflow executions. | <code>string</code> |  | <code>&#34;LOG_ERRORS_ONLY&#34;</code> |
| [roles](variables.tf#L44) | Additional roles to grant to the workflows service account. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#34;roles&#47;workflows.invoker&#34;&#93;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [service_account](outputs.tf#L1) | The workflow service account. |  |
| [workflow](outputs.tf#L6) | The newly created workflow. |  |
<!-- END TFDOC -->
