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
4. Region of deployment to US Only 


## Deployment Steps

1. Clone the repo to your local machine or Cloud Shell:

```bash
git clone https://github.com/DarkWolf-Labs/dino-runner.git
```

2. Change to the directory of the blueprint:

```bash
cd dino-runner/blueprints/serverless/cloud-run-explore
```

You should see this README and some terraform files.

1. To deploy a specific use case, you will need to create a file in this directory called `terraform.tfvars` and follow the corresponding instructions to set variables. Values that are meant to be substituted will be shown inside brackets but you need to omit these brackets. E.g.:

```tfvars
project_id = "[your-project_id]"
```

may become

```tfvars
project_id = "spiritual-hour-331417"
```

Although each use case is somehow built around the previous one they are self-contained so you can deploy any of them at will.

2. The usual terraform commands will do the work:

```bash
terraform init
terraform plan
terraform apply
```

It will take a few minutes. When complete, you should see an output stating the command completed successfully, a list of the created resources, and some output variables with information to access your services.
