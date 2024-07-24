# Google Cloud Storage Module Blueprint

## Introduction

This blueprint contains all the necessary Terraform modules to build and deploy a Google Cloud Dataflow Job 

## Pre-requisite
1. The Principal (user or group) must have Cloud KMS Admin permission at the GCP Level.

## Deployment Steps
1. Update the Variables in the terraform.tfvars
1. Terraform Commands

```bash
terraform init
terraform plan
terraform apply
```
