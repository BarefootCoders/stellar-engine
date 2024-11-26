# Document AI Blueprint
This blueprint demonstrates how to create Processors in Document AI on Google Cloud Platform (GCP).

<!-- BEGIN TOC -->
- [Introduction to Document AI](#introduction-to-document-ai)
- [Disclaimer](#disclaimer)
- [Deployment Steps](#deployment-steps)
- [Demo](#demo)
- [What's Next?](#whats-next)
- [Note](#note)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Introduction to Document AI
Document AI is a document processing and understanding platform that takes unstructured data from documents and transforms it into structured data (specific fields, suitable for a database), making it easier to understand, analyze, and consume. Document AI is built on top of products within Vertex AI with generative AI to help you create scalable, end-to-end, cloud-based document processing applications without specialized machine learning expertise.

## Disclaimer
- The present GCP Terraform Module in this project is set up and intended to be implemented in a FEDRAMP High environment using the Assured Workdloads within the Google Cloud Platform (GCP) organization.

## Deployment Steps
1. Copy the contents of the terraform.tfvars.sample file into your own terraform.tfvars file, then update the variables in this file. For reference update the following variables:

- ```name```  with the name of your processor<br />
- ```project``` with the GCP project id<br />
- ```region``` with the GCP Location <br />
- ```type``` with the type of [Document AI processor](https://cloud.google.com/document-ai/docs/processors-list) you wish to create <br />

2. The usual terraform commands will be used to deploy the processor. To provision this example, run the following from within this directory:

```terraform init ```<br />
```terraform plan``` to see the infrastructure plan<br />
```terraform apply``` to apply the infrastructure build<br />
```terraform destroy``` only if you wish to destroy the built infrastructure<br />

To verify a successful deployment, search for "Document AI" in the Google Cloud Console, then click on "My processors" in the side bar. From here, you will be able to view your newly created processor.

## Demo
This demo is meant to work with the default "OCR_PROCESSOR".
1. Manual file upload.
- Start by clicking on your newly created processor to pull up the "Processor Details" page. 
- At the bottom of this page, you should see an "Upload Test Document" button.
- Use this button to upload the sample file "Winnie_the_Pooh_3_Pages.pdf".
- View the output of the processor.
2. Batch processing.
- View your cloud storage buckets.
- Upload the sample document to "(your-project)-docai-input-bucket".
- View your workflows and click on "docai-workflow"
- Click the "execute" button and change your logging level if desired.
- Click "execute" at the bottom of the screen to start the workflow.
- After the workflow executes, view your buckets again.
- Click on "(your-project)-docai-output-bucket" to view the json output.

## What's Next?
Refer to the [Document AI documentation](https://cloud.google.com/document-ai/docs/send-request#documentai_batch_process_document-python) to learn how to use your processor by through various client libraries. 
If you would like to continue using workflows, then you can view the [documentation](https://cloud.google.com/workflows/docs/create-workflow-terraform) here.

## Note
KMS/CMEK is not currently working for Document AI in Terraform as a cyclical dependency is created; the processor instance creates the Document AI Service Account, but the Service Account must have proper KMS permissions prior to the instance creation. 
If you would still like to use CMEKs with Document AI, you can manually create a processor first so that the Document AI Service Account will exist.
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L7) | Name of the Document AI processor. | <code>string</code> | ✓ |  |
| [project](variables.tf#L12) | The Google Project ID. | <code>string</code> | ✓ |  |
| [region](variables.tf#L17) | The Google Cloud region. | <code>string</code> | ✓ |  |
| [file](variables.tf#L1) | File path of the yaml instructions for the workflow. | <code>string</code> |  | <code>&#34;code&#47;example.yaml&#34;</code> |
| [type](variables.tf#L22) | Type of Document AI model. | <code>string</code> |  | <code>&#34;OCR_PROCESSOR&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L1) | Document AI processor id. |  |
| [input_bucket](outputs.tf#L6) | Bucket that takes documents as input. |  |
| [output_bucket](outputs.tf#L11) | Bucket that stores document processor output. |  |
| [processor](outputs.tf#L16) | Document AI processor. |  |
| [workflow](outputs.tf#L21) | Workflow that runs the batch processing. |  |
<!-- END TFDOC -->