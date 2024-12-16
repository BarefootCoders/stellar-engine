# Data Fusion
This blueprint deploys Data Fusion.

<!-- BEGIN TOC -->
- [Prerequisites](#prerequisites)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Prerequisites
1. Enable Data Fusion API on your main project.

<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [landing_project_id](variables.tf#L7) | Landing project id. | <code>string</code> | ✓ |  |
| [name](variables.tf#L12) | Name of DataFusion instance. | <code>string</code> | ✓ |  |
| [network](variables.tf#L17) | Full path to VPC. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L22) | Project id. | <code>string</code> | ✓ |  |
| [region](variables.tf#L27) | Location to deploy job. | <code>string</code> | ✓ |  |
| [subnet](variables.tf#L32) | Full path to subnet. | <code>string</code> | ✓ |  |
| [kms_key](variables.tf#L1) | Full path to KMS key for pubsub. | <code>string</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L1) | Fully qualified instance id. |  |
| [resource](outputs.tf#L6) | DataFusion resource. |  |
| [service_endpoint](outputs.tf#L11) | DataFusion Service Endpoint. |  |
| [version](outputs.tf#L16) | DataFusion version. |  |
<!-- END TFDOC -->
