# Cloud SQL for PostgreSQL instance.
This blueprint contains all the necessary Terraform modules to build and deploy a Cloud SQL for PostgreSQL instance. Google Cloud SQL for PostgreSQL is a fully-managed database service provided by Google Cloud Platform (GCP). It allows you to create and manage PostgreSQL relational databases in the cloud,
 
## Pre-requisite for Google BigQuery (BigQuery)
1. The Principal (user or group) must enablw BigQuery API in their Google Cloud Project 
2. Have access to the GCP Project ID
3.  You will need an existing [project](https://cloud.google.com/resource-manager/docs/creating-managing-projects) with [billing enabled](https://cloud.google.com/billing/docs/how-to/modify-project) and a user with the “Project owner” [IAM](https://cloud.google.com/iam) role on that project.
4.  __Note__: to grant a user a role, take a look at the [Granting and Revoking Access](https://cloud.google.com/iam/docs/granting-changing-revoking-access#grant-single-role) documentation.

## Disclaimer
- The present GCP Terraform Module in this project is set up and intended to be implemented in an IL5 Impact Level 5 environment using the Assured Workdloads within the Google Cloud Platform (GCP) organization.
- An Assured Workloads and IL5 environments ensures that sensitive data and workloads in GCP adhere to the rigorous security standards mandated by the DoD, making it suitable for government agencies.
 
## How to deploy the Terraform Code. The Deployment Steps
You should see this README and some terraform files.
1. There is a sample ```terraform.tfvars.sample``` available as well.
2. Although each use case is somehow built around the previous one they are self-contained so you can deploy any of them at your will. The usual terraform commands will do the work. To provision this example, run the following from within this directory:

```terraform init ``` to get the plugins<br />
```terraform plan``` to see the infrastructure plan<br />
```terraform apply``` to apply the infrastructure build<br />
```terraform destroy``` to destroy the built infrastructure<br />
 