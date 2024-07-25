# Google Cloud Storage Module Blueprint

## Introduction
This blueprint builds and deploys a Google Cloud Dataflow Job

## Pre-requisite
1. The Principal (user or group) must have Cloud KMS Admin permission at the GCP Level
1. A VNet and Subnet

## Deployment Steps
1. Update the variables in terraform.tfvars
1. Run the following Terraform commands and type "yes" when prompted

```bash
terraform init
terraform plan
terraform apply
```

Note: If you are using a KMS keyring that already exists, you must import it as documented [here](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_key_ring)