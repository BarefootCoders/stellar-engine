# Cloud Translate Blueprint
This blueprint demonstrates how to use the Translation LLM from Vertex AI Model Garden on Google Cloud Platform (GCP).

<!-- BEGIN TOC -->
- [Disclaimer](#disclaimer)
- [Deployment Steps](#deployment-steps)
- [Demo](#demo)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Disclaimer
- The present GCP Terraform Module in this project is set up and intended to be implemented in a FEDRAMP High environment using the Assured Workdloads within the Google Cloud Platform (GCP) organization.
- As of December 2nd, 2024 you must manually allow the translation api. Go to your organization policies and search for constraints/gcp.restrictServiceUsage. In the allowed section, add the following api: "translate.googleapis.com".

## Deployment Steps
1. Copy the contents of the terraform.tfvars.sample file into your own terraform.tfvars file, then update the variables in this file. For reference update the following variables:

- ```project``` with the GCP project id<br />
- ```region``` with the GCP Location <br />
- ```deletion_protection``` to set deletion protection on the created workflow<br />
- ```src_lang``` with the [language](https://cloud.google.com/translate/docs/languages) of your input documents<br />
- ```target_lang``` with the [language](https://cloud.google.com/translate/docs/languages) you would like your documents to be translated into<br />

2. The usual terraform commands will be used to deploy the processor. To provision this example, run the following from within this directory:

```terraform init ```<br />
```terraform plan``` to see the infrastructure plan<br />
```terraform apply``` to apply the infrastructure build<br />
```terraform destroy``` only if you wish to destroy the built infrastructure<br />

To verify a successful deployment, look for workflows in the Google Cloud Console. You should see a newly created workflow named "translate-workflow". Next, check for buckets named "(YOUR-PROJECT-ID)-translate-input" and "(YOUR-PROJECT-ID)-translate-output".

## Demo
If you would like to use the Translation LLM directly from the Google Cloud Console, follow this [link](https://console.cloud.google.com/vertex-ai/studio/translation).

To use the created workflow for batch translations, continue to the following steps:
1. Upload the files from the local samples folder to the input bucket.
2. Go to workflows, and click on your newly created "translate-workflow".
3. Click "Execute", then click "Execute" again.
4. After the workflow executes, look at the output bucket to view your translated documents.
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project](variables.tf#L13) | The Google Project ID. | <code>string</code> | ✓ |  |
| [region](variables.tf#L18) | The Google Cloud region. | <code>string</code> | ✓ |  |
| [deletion_protection](variables.tf#L1) | Deletion proteciton. | <code>bool</code> |  | <code>true</code> |
| [file](variables.tf#L7) | File path of the yaml instructions for the workflow. | <code>string</code> |  | <code>&#34;code&#47;example.yaml&#34;</code> |
| [src_lang](variables.tf#L23) | The source language of the text. | <code>string</code> |  | <code>&#34;es&#34;</code> |
| [target_lang](variables.tf#L29) | The target language to translate into. | <code>string</code> |  | <code>&#34;en&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [input_bucket](outputs.tf#L1) | Bucket that takes documents as input. |  |
| [output_bucket](outputs.tf#L6) | Bucket that stores translated output. |  |
| [workflow](outputs.tf#L11) | Workflow that runs the batch processing. |  |
<!-- END TFDOC -->
