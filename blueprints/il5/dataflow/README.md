## Introduction to Data-flow 
Google manages all of the resources needed to run Dataflow, and this implies that dataflow is a fully managed service. When one runs a Dataflow job, they don't need to manage or provision these virtual machines.  When one runs a Dataflow job, the Dataflow service assigns a pool of worker VMs to execute the pipeline. Furthermore, dataflow is distributed accorss various VMs. This optimizes work based on the characteristics of the pipeline. Also, Dataflow can autoscale by stopping some worker VMs if less is needed as well as provisioning extra worker VM's.

1. The IAM Permissions and Roles ```roles/cloudkms.cryptoKeyEncrypterDecrypter``` is assigned
Obtains access credentials for your user account via a web-based authorization flow. When this command completes successfully, it sets the active account in the current configuration to the account specified.

## Pre-requisite for Data flow (Google cloud platform Data-flow)
1. Have access to the GCP Project ID
2. You will need an existing [project](https://cloud.google.com/resource-manager/docs/creating-managing-projects) with [billing enabled](https://cloud.google.com/billing/docs/how-to/modify-project) and a user with the “Project owner” [IAM](https://cloud.google.com/iam) role on that project.
3. __Note__: to grant a user a role, take a look at the [Granting and Revoking Access](https://cloud.google.com/iam/docs/granting-changing-revoking-access#grant-single-role) documentation.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | Project ID GCP | `string` | n/a | yes |
| region |region/location of project | `string` | n/a | yes |
| name|The name of dataflow instance.| `string` | n/a | yes |
| email|The email of the user| `string` | n/a | yes |
| service_account_email|This is the email of the service account. | `string` | n/a | yes |
| zone |zone of the bastion instance | `string` | n/a | yes |
| compute_service_account_id |The compute service account id.| `string` | n/a | yes |
| kms_key_self_link |This is the self link of the KMS key for disk encryption.| `string` | n/a | yes |
| temp_gcs_location |The location in which the dataflow job will be deployed.| `string` | n/a | yes |
| template_gcs_path |The path in which the dataflow job will be deployed.| `string` | n/a | yes |
| bucket_name |Name of bucket| `string` | n/a | yes |
| keyring | Keyring name | `string` | n/a | yes |
| keys | Key names. | `list(string)` | `[]` | yes |
| iam | Identity and Access Management. |`list(string)` |  `[]` | yes |
| iam bindings| associates IAM policies with members | `list(string)`|  `[]` | yes |
| default|contains the duration, roation, protection, algorithm of the keys  | `list(string)` | `[]` | yes |

## How to deploy the Terraform Code. The Deployment Steps
You should see this README and some terraform files.
1. Update the Variables in the variables.tf and also the properties within the keys variables. For reference update the following variables and associated properties
2. There is a sample ```terraform.tfvars.sample``` available as well.
3. Although each use case is somehow built around the previous one they are self-contained so you can deploy any of them at your will. The usual terraform commands will do the work:

```bash
terraform init
terraform plan
terraform apply
```

It will take a few minutes. When complete, you should see an output stating the command completed successfully, a list of the created resources.
