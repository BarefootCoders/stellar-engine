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
| email|The email of the user| `string` | n/a | yes |
| compute_service_account_id |The compute service account id.| `string` | n/a | yes |
| bucket_name |Name of bucket| `string` | n/a | yes |
| dataflow_service_account_id |Name of dataflow service account| `string` | n/a | yes |
| keyring | Keyring name | `KMS keyring to use for encryption. Use terraform import 'module.kms.google_kms_key_ring.default[0]' projects/<your-project>/locations/<your location>/keyRings/<your-keyring> if you want to use an existing keyring` | n/a | yes |
| keys | Key names. | `Key to use for encryption - defaults to the name "bastion". Use terraform import 'module.kms.google_kms_crypto_key.default["bastion"]' projects/<your-project>/locations/<your-location>/keyRings/<your-keyring>/cryptoKeys/bastion if you want to use an existing key` | `[]` | yes |
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

module.kms.google_kms_crypto_key_iam_binding.authoritative["my-key.roles/cloudkms.cryptoKeyEncrypterDecrypter"]: Modifying... [id=projects/my-dev-repo/locations/us-east4/keyRings/my-keyring/cryptoKeys/my-key/roles/cloudkms.cryptoKeyEncrypterDecrypter]
module.kms.google_kms_crypto_key_iam_binding.authoritative["my-key.roles/cloudkms.cryptoKeyEncrypterDecrypter"]: Modifications complete after 5s [id=projects/my-dev-repo/locations/us-east4/keyRings/my-keyring/cryptoKeys/my-key/roles/cloudkms.cryptoKeyEncrypterDecrypter]
google_storage_bucket.bucket: Creating...
google_storage_bucket.bucket: Creation complete after 1s [id=bucket-name]

Apply complete! Resources: 1 added, 1 changed, 0 destroyed.