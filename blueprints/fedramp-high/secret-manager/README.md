# Secret Manager Blueprint
This blueprint demonstrates how to create Secrets on Google Cloud Platform (GCP) with Customer-Managed Encryption Keys (CMEK) using Cloud KMS. 

## Introduction to Secret Manager
Secret Manager is a secure and convenient storage system for API keys, passwords, certificates, and other sensitive data.
- Easily follow the principle of least privilege with Secret Manager's Cloud IAM roles. You can grant individual permissions to secrets and separate the ability to manage secrets from the ability to access their data.
- Secret Manager enables simple life cycle management with first class versioning and the ability to pin requests to the latest version of a secret. You can use Cloud Functions to automate rotation.
- With Cloud Audit Logs integration, every interaction with Secret Manager generates an audit log. This integration makes meeting audit and compliance requirements easy.
- Secret data is immutable and most operations take place on secret versions. With Secret Manager, you can pin a secret to specific versions like "42" or floating aliases like "latest."

## Disclaimer
- The present GCP Terraform Module in this project is set up and intended to be implemented in a FEDRAMP High environment using the Assured Workdloads within the Google Cloud Platform (GCP) organization.
- Warning: managing versions will persist their data (the actual secret you want to protect) in the Terraform state in unencrypted form, accessible to any identity able to read or pull the state file. DO NOT MANAGE VERSIONS IN TERRAFORM unless the state file is being stored remotely and is encrypted

## Requirements

These sections describe requirements for using this module.

### IAM

The following roles must be used to provision the resources of this module:

- Cloud KMS Admin: `roles/cloudkms.admin` or
- Owner: `roles/owner`

### APIs

A project with the following APIs enabled must be used to host the
resources of this module:

- Google Cloud Key Management Service: `cloudkms.googleapis.com`