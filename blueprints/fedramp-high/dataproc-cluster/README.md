Copyright 2023 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Dataproc Blueprint
This blueprint deploys a dataproc cluster and meets all compliane with Assured Workloads FedRAMP High environments as of 14 NOV 2024.

## Prequisites
1. Enable Cloud Dataproc API

## Deployment Steps
1. Update the variables in terraform.tfvars
1. Run the following Terraform commands and type "yes" when prompted

```bash
terraform init
terraform plan
terraform apply
```

Note: This deployment DOES NOT use KMS for the cluster, although it is used on the storage buckets.

<!-- BEGIN TOC -->
- [Prequisites](#prequisites)
- [Deployment Steps](#deployment-steps)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [cluster_name](variables.tf#L16) | Name of the Dataproc cluster. | <code>string</code> | ✓ |  |
| [dataproc_bucket_name](variables.tf#L21) | Name of the gcs bucket that will be created and used with Dataproc. This must be globally unique. | <code>string</code> | ✓ |  |
| [dataproc_name](variables.tf#L26) | Name of the Dataproc instance. | <code>string</code> | ✓ |  |
| [firewall_name](variables.tf#L31) | The Dataproc firewall name. | <code>string</code> | ✓ |  |
| [iac_project_id](variables.tf#L36) | The ID of the iac project where the KMS key is. | <code>string</code> | ✓ |  |
| [key](variables.tf#L41) | KMS key name. | <code>string</code> | ✓ |  |
| [keyring](variables.tf#L46) | KMS keyring name. | <code>string</code> | ✓ |  |
| [landing_project_id](variables.tf#L51) | The ID of the landing zone project where the VPC is. | <code>string</code> | ✓ |  |
| [network_name](variables.tf#L56) | The network name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L61) | The ID of the main project. | <code>string</code> | ✓ |  |
| [subnet_name](variables.tf#L72) | The subnet name. | <code>string</code> | ✓ |  |
| [region](variables.tf#L66) | The region in which to provision resources. | <code>string</code> |  | <code>&#34;us-east4&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [dataproc_bucket](outputs.tf#L1) | GCS Bucket for DataProc. |  |
| [dataproc_cluster](outputs.tf#L6) | Dataproc cluster name. |  |
<!-- END TFDOC -->
