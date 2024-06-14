# Google Cloud Key Management Service (Cloud KMS) Project
This blueprint contains all the necessary Terraform modules to build and deploy a Cloud Key Management: Manage encryption keys on Google Cloud.


## Introduction Google Cloud Key Management Service (Cloud KMS)
Google Cloud Key Management Service (Cloud KMS) lets you create and manage encryption keys for use in compatible Google Cloud services and in your own applications. Using Cloud KMS, you can Generate software or hardware keys, import existing keys into Cloud KMS, or link external keys in your compatible external key management (EKM) system. Allows managing a keyring, zero or more keys in the keyring, and IAM role bindings on individual keys.

1. The Rotation Period ``` rotation_period ``` is set to 90 days,
2. The Destory Schedulded Duration is ``` destroy_scheduled_duration ``` is set to 30 days
3. The IAM Permissions and Roles ```roles/cloudkms.cryptoKeyEncrypterDecrypter``` is assigned

## Pre-requisite for Google Cloud Key Management Service (Cloud KMS)
1. The Principal (user or group) must have Google Cloud Key Management Service (Cloud KMS) Admin permission at the GCP Level.
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
    name     = "may6v3-keyring"
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

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

keyring-id = "projects/project-id-123/locations/us-east4/keyRings/name-of-the-keyring"
keyring-location = "us-east4"
keyring-name = "name-of-the-keyring"
keyring-resource = {
  "id" = "projects/project-id-123/locations/us-east4/keyRings/name-of-the-keyring"
  "location" = "us-east4"
  "name" = "name-of-the-keyring"
  "project" = "project-id-123"
  "timeouts" = null /* object */
}
keyrings-keys = {
  "keryrings-key" = {
    "crypto_key_backend" = ""
    "destroy_scheduled_duration" = "2592000s"
    "effective_labels" = tomap({
      "team" = "dino-runner"
    })
    "id" = "projects/project-id-123/locations/us-east4/keyRings/name-of-the-keyring/cryptoKeys/keryrings-runner-key"
    "import_only" = false
    "key_ring" = "projects/project-id-123/locations/us-east4/keyRings/name-of-the-keyring"
    "labels" = tomap({
      "team" = "dino-runner"
    })
    "name" = "keryrings-runner-key"
    "primary" = tolist([
      {
        "name" = "projects/project-id-123/locations/us-east4/keyRings/name-of-the-keyring/cryptoKeys/keryrings-runner-key/cryptoKeyVersions/1"
        "state" = "ENABLED"
      },
    ])
    "purpose" = "ENCRYPT_DECRYPT"
    "rotation_period" = "7776000s"
    "skip_initial_version_creation" = false
    "terraform_labels" = tomap({
      "team" = "dino-runner"
    })
    "timeouts" = null /* object */
    "version_template" = tolist([
      {
        "algorithm" = "GOOGLE_SYMMETRIC_ENCRYPTION"
        "protection_level" = "HSM"
      },
    ])
  }
}
qualified_key_ids = {
  "keryrings-runner-key" = "projects/project-id-123/locations/us-east4/keyRings/name-of-the-keyring/cryptoKeys/keryrings-runner-key"
}


```
