# Google Cloud Storage Module Blueprint

## Introduction

This blueprint contains all the necessary Terraform modules to build and deploy a Google Cloud Storage Bucket meeting the following requirements

1. Enforce that all the GCP Buckets are ONLY Private with NO PUBLIC access 
```
public_access_prevention = "enforced"
```
2.  Enable Use Autoclass, set it to true.
```
autoclass { enabled = true }
```
3. Force  Customer-Managed Encryption Keys (CMEK) Cloud KMS for Google Cloud Storage
4. Region of deployment to US Only  for example in us-east4 and us-central1


## Pre-requisite
1. The Principal (user or group) must have Cloud KMS Admin permission at the GCP Level.

## Disclaimer
- The present GCP Terraform Module in this project is set up and intended to be implemented in an IL5 Impact Level 5 environment using the Assured Workdloads within the Google Cloud Platform (GCP) organization.
- An Assured Workloads and IL5 environments ensures that sensitive data and workloads in GCP adhere to the rigorous security standards mandated by the DoD, making it suitable for government agencies.


## Deployment Steps
You should see this README and some terraform files.
1.  Update the Variables in the variables.tf that are marked as "# TODO: Update"
2. The list of variables to be updated are project_id, keyring, prefix, name, location, email


```tfvars
project_id = "[your-project_id]"
```

may become

```tfvars
project_id = "YOUR-PROJECT-ID-123"
```

The Location

 ```tfvars
location = "us-east4"
```


Although each use case is somehow built around the previous one they are self-contained so you can deploy any of them at will.

3. The usual terraform commands will do the work:

```bash
terraform init
terraform plan
terraform apply
```

It will take a few minutes. When complete, you should see an output stating the command completed successfully, a list of the created resources.

```
module.kms.google_kms_key_ring.default[0]: Creating...
module.kms.google_kms_key_ring.default[0]: Creation complete after 0s [id=projects/project-123-abc-dev/locations/us-east4/keyRings/testname-keyring]
module.kms.google_kms_key_ring_iam_binding.authoritative["roles/cloudkms.cryptoKeyEncrypterDecrypter"]: Creating...
module.kms.google_kms_crypto_key.default["default"]: Creating...
module.kms.google_kms_crypto_key.default["default"]: Creation complete after 1s [id=projects/project-123-abc-dev/locations/us-east4/keyRings/testname-keyring/cryptoKeys/default]
module.gcs.google_storage_bucket.bucket: Creating...
module.gcs.google_storage_bucket.bucket: Creation complete after 1s [id=il5-bucketapr30]
module.kms.google_kms_key_ring_iam_binding.authoritative["roles/cloudkms.cryptoKeyEncrypterDecrypter"]: Creation complete after 5s [id=projects/project-123-abc-dev/locations/us-east4/keyRings/testname-keyring/roles/cloudkms.cryptoKeyEncrypterDecrypter]

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
```