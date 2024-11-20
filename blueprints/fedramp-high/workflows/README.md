
# Workflows Blueprint
This blueprint demonstrates how to create a workflow on Google Cloud Platform (GCP) with Customer-Managed Encryption Keys (CMEK) using Cloud KMS.

## Introduction to Workflows
Workflows is a fully managed orchestration platform that executes services in an order that you define. These workflows can combine services including custom services hosted on Cloud Run or Cloud Run functions, Google Cloud services such as Cloud Vision AI and BigQuery, and any HTTP-based API.
By incorporating Workflows into solutions, you can make service dependencies explicit and observable end-to-end. A workflow that specifies an application, operational, or business process provides a source-of-truth or canonical narrative for the process.

## Disclaimer
- The present GCP Terraform Module in this project is set up and intended to be implemented in a FEDRAMP High environment using the Assured Workdloads within the Google Cloud Platform (GCP) organization.
<!-- BEGIN TFDOC -->

<!-- END TFDOC -->
## Deployment Steps
1. Copy the contents of the terraform.tfvars.sample file into your own terraform.tfvars file, then update the variables in this file. For reference update the following variables:

- ```key```  with your encryption key<br />
- ```name```  with the name of your processor<br />
- ```project``` with the GCP project id<br />
- ```region``` with the GCP location <br />

2. The usual terraform commands will be used to deploy the processor. To provision this example, run the following from within this directory:

```terraform init ```<br />
```terraform plan``` to see the infrastructure plan<br />
```terraform apply``` to apply the infrastructure build<br />
```terraform destroy``` only if you wish to destroy the built infrastructure<br />

To verify a successful deployment, search for "Document AI" in the Google Cloud Console, then click on "My processors" in the side bar. From here, you will be able to view your newly created processor.

## Demo
