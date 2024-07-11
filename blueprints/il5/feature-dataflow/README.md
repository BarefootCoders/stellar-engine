## Disclaimer
- The present GCP Terraform Module in this project is set up and intended to be implemented in an IL5 Impact Level 5 environment using the Assured Workdloads within the Google Cloud Platform (GCP) organization.
- An Assured Workloads and IL5 environments ensures that sensitive data and workloads in GCP adhere to the rigorous security standards mandated by the DoD, making it suitable for government agencies.

## Introduction to Data-flow 
This project will set up a dataflow job that can read messages from a Google Pub/Sub topic and writes them to a Google BigQuery table. Google manages all of the resources needed to run Dataflow, and this implies that dataflow is a fully managed service. When one runs a Dataflow job, they don't need to manage or provision these virtual machines.  When one runs a Dataflow job, the Dataflow service assigns a pool of worker VMs to execute the pipeline. Furthermore, dataflow is distributed accorss various VMs. This optimizes work based on the characteristics of the pipeline. Also, Dataflow can autoscale by stopping some worker VMs if less is needed as well as provisioning extra worker VM's. 

1. The IAM Permissions and Roles ```roles/cloudkms.cryptoKeyEncrypterDecrypter``` is assigned
Obtains access credentials for your user account via a web-based authorization flow. When this command completes successfully, it sets the active account in the current configuration to the account specified.

## Pre-requisite for Data flow (Google cloud platform Data-flow)
1. Have access to the GCP Project ID
2. Enable Cloud Storage API and grant key admin permissions for your key. [https://console.cloud.google.com/storage]
3. You will need an existing [project](https://cloud.google.com/resource-manager/docs/creating-managing-projects) with [billing enabled](https://cloud.google.com/billing/docs/how-to/modify-project) and a user with the “Project owner” [IAM](https://cloud.google.com/iam) role on that project.
4. __Note__: to grant a user a role, take a look at the [Granting and Revoking Access](https://cloud.google.com/iam/docs/granting-changing-revoking-access#grant-single-role) documentation.

## Give these permissions to your publisher service account                           
Backup and DR Cloud Storage Operator
Cloud Dataflow Service Agent
Dataflow Developer
IAM OAuth Client Admin
IAM OAuth Client Viewer
Pub/Sub Publisher

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | Project ID GCP | `string` | n/a | yes |
| region |region of the project | `string` | n/a | yes |
| location |location of dataset | `string` | n/a | yes |
| email|The email of the user| `string` | n/a | yes |
| network|The network of the data pipeline.| `string` | n/a | yes |
| storage_class|The storage class of the bucket| `string` | n/a | yes |
| prefix|The prefix for every resource| `string` | n/a | yes |
| bigquery_dataset_id|The id of the dataset| `string` | n/a | yes |
| pubsub_topic_name|The name of the topic| `string` | n/a | yes |
| pubsub_subscription_name|The name of the subscription| `string` | n/a | yes |
| input_topic|The name of the input within the parameters| `string` | n/a | yes |
| output_table|The name of the output| `string` | n/a | yes |
| bigquery_table_id|The name of the BigQuery table within the parameters| `string` | n/a | yes |
| dataflow_name|The name of the dataflow job| `string` | n/a | yes |
| zone|The zone of the project| `string` | n/a | yes |
| template_gcs_path |The template used for the dataflow job| `string` | n/a | yes |
| compute_service_account_id |The compute service account id.| `string` | n/a | yes |
| bucket_name |Name of bucket| `string` | n/a | yes |
| dataflow_service_account_id |Name of dataflow service account| `string` | n/a | yes |
| keyring | Keyring name | `KMS keyring to use for encryption. Use terraform import 'module.kms.google_kms_key_ring.default[0]' projects/<your-project>/locations/<your location>/keyRings/<your-keyring> if you want to use an existing keyring` | n/a | yes |
| keys | Key names. | `Key to use for encryption - defaults to the name "keyring-dataflow". Use terraform import 'module.kms.google_kms_crypto_key.default["keyring-dataflow"]' projects/<your-project>/locations/<your-location>/keyRings/<your-keyring>/cryptoKeys/bastion if you want to use an existing key` | `[]` | yes |
| iam | Identity and Access Management. |`list(string)` |  `[]` | yes |
| iam bindings| associates IAM policies with members | `list(string)`|  `[]` | yes |
| default|contains the duration, roation, protection, algorithm of the keys  | `list(string)` | `[]` | yes |

## How to deploy the Terraform Code. The Deployment Steps                  
You should see this README and some terraform files.
1. Create an ```terraform.tfvars```. Copy the content from the  sample ```terraform.tfvars.sample```. Update the values in the ```terraform.tfvars```
2. Although each use case is somehow built around the previous one they are self-contained so you can deploy any of them at your will. The usual terraform commands will do the work:
```bash
terraform init
terraform plan
terraform apply
```

Verification of a successful deployment? 
The dataset in dataflow storage bucket will look like this in your Google Cloud Console. 
<img width="1440" alt="Screenshot 2024-06-20 at 12 55 50 PM" src="https://github.com/DarkWolf-Labs/dino-runner/assets/167789559/ffff1325-8009-4cbd-a0bc-dfa42d2b493f">


It will take a few minutes. When complete, you should see an output stating the command completed successfully, a list of the created resources.

module.kms.google_kms_key_ring.default[0]: Creating...
module.kms.google_kms_key_ring.default[0]: Creation complete after 1s [id=projects/my-project-id/locations/us-east4/keyRings/my-keyring]
module.kms.google_kms_key_ring_iam_binding.authoritative["roles/cloudkms.cryptoKeyEncrypterDecrypter"]: Creating...
module.kms.google_kms_crypto_key.default["key"]: Creating...
module.kms.google_kms_crypto_key.default["key"]: Creation complete after 1s [id=projects/my-project-id/locations/us-east4/keyRings/my-keyring/cryptoKeys/key]
module.kms.google_kms_crypto_key_iam_binding.authoritative["key.roles/cloudkms.cryptoKeyEncrypterDecrypter"]: Creating...
module.kms.google_kms_key_ring_iam_binding.authoritative["roles/cloudkms.cryptoKeyEncrypterDecrypter"]: Creation complete after 5s [id=projects/my-project-id/locations/us-east4/keyRings/my-keyring/roles/cloudkms.cryptoKeyEncrypterDecrypter]
module.kms.google_kms_crypto_key_iam_binding.authoritative["key.roles/cloudkms.cryptoKeyEncrypterDecrypter"]: Creation complete after 5s [id=projects/my-project-id/locations/us-east4/keyRings/my-keyring/cryptoKeys/key/roles/cloudkms.cryptoKeyEncrypterDecrypter]
google_kms_crypto_key_iam_binding.binding: Creating...
module.gcs.google_storage_bucket.bucket: Creating...
module.gcs.google_storage_bucket.bucket: Creation complete after 3s [id=dev-bucket-name]
google_kms_crypto_key_iam_binding.binding: Creation complete after 5s [id=projects/my-project-id/locations/us-east4/keyRings/my-keyring/cryptoKeys/key/roles/cloudkms.cryptoKeyEncrypterDecrypter]


Apply complete! Resources: 1 added, 1 changed, 0 destroyed.

Outputs:

bigquery_dataset_id = "my-dataset"
bigquery_table_id = "my-bigquery-table-id"
bucket_name = "my-bucket"
dataflow_job_name = "my-dataflow-job-name"
dataflow_service_account_email = "dataflow-user@my-project-id-dev.iam.gserviceaccount.com"
pubsub_topic_name = "topic"
temp_gcs_location = "gs://gs://my-bucket/temp//tmp_dir"
template_gcs_path = "gs://dataflow-templates-us-east4/latest/PubSub_to_BigQuery"
