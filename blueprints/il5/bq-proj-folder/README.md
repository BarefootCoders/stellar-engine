# Google BigQuery (BigQuery) Project
This blueprint contains all the necessary Terraform modules to build and deploy a BigQuery project on Google Cloud.


## Introduction Google BigQuery (BigQuery)
Google BigQuery is a fully-managed, serverless data system in which querying data is made possible. Database does not need to be constantly monitored, and users can levarage data and analyze the data.
1. The Rotation Period ``` rotation_period ``` is set to 90 days, 
2. The Destory Schedulded Duration is ``` destroy_scheduled_duration ``` is set to 30 days 
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
| email | Email address of the user. | `string` | n/a | yes |
| location | Location for the keyring. | `string` | n/a | yes |
| keyring | Keyring name. | `string` | n/a | yes |
| project_id | Project ID GCP | `string` | n/a | yes |
| keys | Key names. | `list(string)` | `[]` | yes |
| keys.updated-the-runner-key-name | The name to be given to runner | `string` |  n/a | yes |
| keys.labels.teams | The Label to be given to the keys | `string` |  n/a | yes |
| keys.iam | Email address of the user in user:update-the-email-address-here"  | `string` |  n/a | yes |


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

It will take a few minutes. When complete, you should see an output stating the command completed successfully, a list of the created resources.

The Output will look like following
```
module.kms.google_kms_key_ring.default[0]: Refreshing state... [id=projects/project_id/locations/us-east4/keyRings/may-bq-keyring]

Terraform used the selected providers to generate the following
execution plan. Resource actions are indicated with the
following symbols:
  + create

Terraform will perform the following actions:

  # module.bigquery-dataset.google_bigquery_dataset.default will be created
  + resource "google_bigquery_dataset" "default" {
      + creation_time              = (known after apply)
      + dataset_id                 = "dataset_01"
      + default_collation          = (known after apply)
      + delete_contents_on_destroy = false
      + description                = "This dataset has customer managed encrytped keys, is updated in real-time, and accessed by restricted roles."
      + effective_labels           = (known after apply)
      + etag                       = (known after apply)
      + id                         = (known after apply)
      + is_case_insensitive        = (known after apply)
      + last_modified_time         = (known after apply)
      + location                   = "US-east4"
      + max_time_travel_hours      = "168"
      + project                    = "project"
      + self_link                  = (known after apply)
      + storage_billing_model      = (known after apply)
      + terraform_labels           = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.


Changes to Outputs:
  + id      = (known after apply)

plan complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

```