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

## Requirements

1. The Principal (user or group) must have Cloud KMS Admin permission at the GCP Level
1. A VPC Network and Subnet
1. [Enable Dataflow API](https://console.developers.google.com/apis/api/dataflow.googleapis.com/overview?project=tnbsea-dev-tapand-dev)

## Deployment Steps
1. Update the variables in terraform.tfvars
1. Run the following Terraform commands and type "yes" when prompted

```bash
terraform init
terraform plan
terraform apply
```

Note: If you are using a KMS keyring that already exists, you must import it as documented [here](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_key_ring)

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 5.38.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_gcs"></a> [gcs](#module\_gcs) | ../../../modules/gcs | n/a |
| <a name="module_kms"></a> [kms](#module\_kms) | ../../../modules/kms | n/a |

## Resources

| Name | Type |
|------|------|
| [google_compute_firewall.dataflow](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_dataflow_job.job](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dataflow_job) | resource |
| [google_project_iam_member.dataflow_worker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_service_account.dataflow_worker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_project.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_firewall_ports"></a> [allowed\_firewall\_ports](#input\_allowed\_firewall\_ports) | The allowed ports for the firewall. Dataflow requires 12345 and 12346. | `list(string)` | <pre>[<br>  12345,<br>  12346<br>]</pre> | no |
| <a name="input_allowed_source_ranges"></a> [allowed\_source\_ranges](#input\_allowed\_source\_ranges) | These are the allowed source ranges. | `list(string)` | n/a | yes |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | This is the name of the bucket. | `string` | n/a | yes |
| <a name="input_dataflow_name"></a> [dataflow\_name](#input\_dataflow\_name) | This is the name of the dataflow job. | `string` | n/a | yes |
| <a name="input_keyring"></a> [keyring](#input\_keyring) | Keyring attributes. | <pre>object({<br>    location = string<br>    name     = string<br>  })</pre> | n/a | yes |
| <a name="input_keys"></a> [keys](#input\_keys) | Key names and base attributes. Set attributes to null if not needed. | <pre>map(object({<br>    destroy_scheduled_duration    = optional(string)<br>    rotation_period               = optional(string)<br>    labels                        = optional(map(string))<br>    purpose                       = optional(string, "ENCRYPT_DECRYPT")<br>    skip_initial_version_creation = optional(bool, false)<br>    version_template = optional(object({<br>      algorithm        = string<br>      protection_level = optional(string, "HSM")<br>    }))<br><br>    iam = optional(map(list(string)), {})<br>    iam_bindings = optional(map(object({<br>      members = list(string)<br>      role    = string<br>      condition = optional(object({<br>        expression  = string<br>        title       = string<br>        description = optional(string)<br>      }))<br>    })), {})<br>    iam_bindings_additive = optional(map(object({<br>      member = string<br>      role   = string<br>      condition = optional(object({<br>        expression  = string<br>        title       = string<br>        description = optional(string)<br>      }))<br>    })), {})<br>  }))</pre> | n/a | yes |
| <a name="input_network"></a> [network](#input\_network) | The email of the user. | `string` | n/a | yes |
| <a name="input_parameters"></a> [parameters](#input\_parameters) | Daraflow Paramaters | `map(string)` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | This is the prefix for all resources. | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the project in which to provision resources. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region in which to provision resources. | `string` | `"us-east4"` | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | This is the storage class of the storage bucket. | `string` | n/a | yes |
| <a name="input_subnet"></a> [subnet](#input\_subnet) | The email of the user. | `string` | n/a | yes |
| <a name="input_template_gcs_path"></a> [template\_gcs\_path](#input\_template\_gcs\_path) | This is the template path of the dataflow job. | `string` | n/a | yes |
| <a name="input_zone"></a> [zone](#input\_zone) | This is the name of the zone. | `string` | `"us-east4"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dataflow-job"></a> [dataflow-job](#output\_dataflow-job) | Dataflow job. |
| <a name="output_gcs-bucket"></a> [gcs-bucket](#output\_gcs-bucket) | GCS Bucket. |
