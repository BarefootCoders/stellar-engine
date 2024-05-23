# Google BigQuery (BigQuery) Project
This blueprint contains all the necessary Terraform modules to build and deploy a BigQuery project on Google Cloud.

## Introduction Google BigQuery (BigQuery)
Google BigQuery is a fully-managed, serverless data system in which querying data is made possible. Database does not need to be constantly monitored, and users can levarage data and analyze the data.
1. The Rotation Period ``` rotation_period ``` is set to 90 days indicated by 7776000s seconds, 
2. The Destory Schedulded Duration is ``` destroy_scheduled_duration ``` is set to 30 days indicated by 2592000 seconds.
3. The IAM Permissions and Roles ```roles/cloudkms.cryptoKeyEncrypterDecrypter``` is assigned

## Pre-requisite for Google BigQuery (BigQuery)
1. The Principal (user or group) must enablw BigQuery API in their Google Cloud Project 
2. Have access to the GCP Project ID
3.  You will need an existing [project](https://cloud.google.com/resource-manager/docs/creating-managing-projects) with [billing enabled](https://cloud.google.com/billing/docs/how-to/modify-project) and a user with the “Project owner” [IAM](https://cloud.google.com/iam) role on that project.
4.  __Note__: to grant a user a role, take a look at the [Granting and Revoking Access](https://cloud.google.com/iam/docs/granting-changing-revoking-access#grant-single-role) documentation.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | Project ID GCP | `string` | n/a | yes |
| id |Dataset id | 
`string` | n/a | yes |
| region |Region of the project | `string` | n/a | yes |
| keyring | Keyring name | `string` | n/a | yes |
| location | Location of dataset| `string` | n/a | yes |
| keys | Key names. | 
`list(string)` | `[]` | yes |
| iam | Identity and Access Management. |
 `list(string)` |  `[]` | yes |
| iam bindings| associates IAM policies with members | 
 `list(string)`|  `[]` | yes |
| default|contains the duration, roation, protection, algorithm of the keys  | 
`list(string)` | `[]` | yes |
| email | User email. | 
`string` | n/a | yes |

## How to deploy the Terraform Code. The Deployment Steps
You should see this README and some terraform files.
1. Update the Variables in the variables.tf and also the properties within the keys variables. For reference update the following variables and associated properties

- ```project_id```  with your GCP Project ID<br />
-  ```email```  with your email address<br />
- ```location```  with the GCP Location<br />
- ```keyring``` with the location of the keyring and the name of the 
keyring, for example <br />
```bash 
  default = {
    location = "us-east4"
    name     = "may-bq-keyring"
  }
```
- ```keys```  with the right properties, update the ```updated-the-runner-key-name``` , ```labels = { "team" = ``` , 
```iam = { roles/cloudkms.cryptoKeyEncrypterDecrypter = ["user:YOUR-EMAIL-ADDRESS]```

2. There is a sample ```terraform.tfvars.sample``` available as well.
3. Although each use case is somehow built around the previous one they are self-contained so you can deploy any of them at your will. The usual terraform commands will do the work. To provision this example, run the following from within this directory:

```terraform init ``` to get the plugins<br />
```terraform plan``` to see the infrastructure plan<br />
```terraform apply``` to apply the infrastructure build<br />
```terraform destroy``` to destroy the built infrastructure<br />

Verification of a successful deployment? 
The dataset in BigQuery will look like this in your Google Cloud Console.
![Deployment of BigQuery Dataset](https://github.com/DarkWolf-Labs/dino-runner/assets/167789559/c34d61ae-6fdb-4b62-a33e-f441b84f94ed)

It will take a few minutes. When complete, you should see an output stating the command completed successfully, a list of the created resources.
The Output will look like following
```
module.kms.google_kms_key_ring.default[0]: Refreshing state... [id=projects/project_id/locations/us-east4/keyRings/may-bq-keyring]

Terraform used the selected providers to generate the following
execution plan. Resource actions are indicated with the
following symbols:
  Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs: 

id = "projects/my-project/datasets/dataset_name"
keyring = {
  "id" = "projects/my-project/locations/us-east4/keyRings/may-bq-keyring-"
  "location" = "us-east4"
  "name" = "may-bq-keyring-8"
  "project" = "my-project"
  "timeouts" = null /* object */
}
materialized_view_ids = {}
materialized_views = {}
self_link = "https://bigquery.googleapis.com/bigquery/v2/projects/my-project/datasets/dataset_name"
table_ids = {}
tables = {}
view_ids = {}
views = {}
```
