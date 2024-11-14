# MLOps with Vertex AI
This blueprint demonstrates how to create a Vertex AI Workbench on Google Cloud Platform (GCP) with Customer-Managed Encryption Keys (CMEK) using Cloud KMS. 

## Introduction to Vertex AI
Vertex AI is a fully-managed, unified AI development platform for building and using generative AI. Access and utilize Vertex AI Studio, Agent Builder, and 150+ foundation models. Evaluate, tune, and deploy generative AI models or train your own custom models. 
This example implements the infrastructure required to deploy an end-to-end [MLOps process](https://services.google.com/fh/files/misc/practitioners_guide_to_mlops_whitepaper.pdf) using [Vertex AI](https://cloud.google.com/vertex-ai) platform.

## Disclaimer
- The present GCP Terraform Module in this project is set up and intended to be implemented in either a FedRAMP-High or IL5 (Impact Level 5) environment using the Assured Workloads within the Google Cloud Platform (GCP) organization.

## Architecture
The blueprint will deploy all the required resources to have a fully functional MLOPs environment containing:

1. Vertex Workbench (for the experimentation environment).
1. An external Shared VPC must be configured using the `network_config`variable.
1. GCS buckets to host Vertex AI and Cloud Build Artifacts. By default the buckets will be regional and should match the Vertex AI region for the different resources (i.e. Vertex Managed Dataset) and processes (i.e. Vertex trainining).
1. BigQuery Dataset where the training data will be stored. This is optional, since the training data could be already hosted in an existing BigQuery dataset.
1. Artifact Registry Docker repository to host the custom images.
1. Service account (`PREFIX-sa-mlops`) with the minimum permissions required by Vertex AI and Dataflow (if this service is used inside of the Vertex AI Pipeline).
1. Service account (`PREFIX-sa-github@`) to be used by Workload Identity Federation, to federate Github identity (Optional).
1. Secret Manager to store the Github SSH key to get access the CICD code repo.

## Overview
![MLOps project description](./images/mlops_projects.png "MLOps project description")

## User groups
Assign roles relying on User groups is a way to decouple the final set of permissions from the stage where entities and resources are created, and their IAM bindings defined. You can configure the group names through the `groups` variable. These groups should be created before launching Terraform.

We use the following groups to control access to resources:

- *Data Scientist* (gcp-ml-ds@<company.org>). They manage notebooks and create ML pipelines.
- *ML Engineers* (gcp-ml-eng@<company.org>). They manage the different Vertex resources.
- *ML Viewer* (gcp-ml-eng@<company.org>). Group with wiewer permission for the different resources.

Please note that these groups are not suitable for production grade environments. Roles can be customized in the `main.tf`file.

## Instructions
### Deploy the experimentation environment
- Create a `terraform.tfvars` file and specify the variables to match your desired configuration. You can use the provided `terraform.tfvars.sample` as reference.
- Before choosing a region to create your resources in, it is recommended to view your system [quotas](https://console.cloud.google.com/iam-admin/quotas) in order to check which regions have access to GPU and TPU accelerators. If you choose a region where the quota is 0, you will have to request a quota increase (common accelerators are NVIDIA_A100 and NVIDIA_H100). It is recommended to create project resources in the 'us-central1' region.
- When configuring your network settings, remeber that you must use a shared VPC. It is recomended that you have a separate 'networking project' that manages network traffic, and share this VPC to any projects that need access to it. This shared VPC must have internet access or JupyterLabs will not work. In addition, the account that runs the terraform code must have the Compute Shared VPC Admin role at an organization level. 
- Run `terraform init` and `terraform apply`

## Demo
To try out the new notebook, you can use the provided code sample (the .ipynb file), adapted from [here](https://github.com/GoogleCloudPlatform/vertex-ai-samples/blob/main/notebooks/community/model_garden/model_garden_pytorch_flux.ipynb). Alternatively, you can view the list of [Vertex AI code samples](https://cloud.google.com/vertex-ai/docs/samples) to find one that you like. Simply open the Google Cloud Console and navigate to Vertex AI workbenches. Under the list of instances, you should see your newly created workbench instance. Click on the button that says "Open JupyterLab" to use your workbench. Within JupyterLab, you should see the option to upload files. Upload a demo notebook, then update the variables as necessary (in the provided demo, you will have to update BUCKET_URI, REGION, and PROJECT_ID). 

## What's next?
This blueprint can be used as a building block for setting up an end2end ML Ops solution. As next step, you can follow this [guide](https://cloud.google.com/architecture/architecture-for-mlops-using-tfx-kubeflow-pipelines-and-cloud-build) to setup a Vertex AI pipeline and run it on the deployed infrastructure.

## Usage
Basic usage of this module is as follows:

```hcl
module "test" {
  source = "./fabric/blueprints/data-solutions/vertex-mlops/"
  labels = {
    "env"  = "dev",
    "team" = "ml"
  }
  bucket_name          = "gcs-test"
  dataset_name         = "bq_test"
  identity_pool_claims = "attribute.repository/ORGANIZATION/REPO"
  notebooks = {
    "myworkbench" = {
      type = "USER_MANAGED"
    }
  }
  prefix = var.prefix
  project_config = {
    billing_account_id = var.billing_account_id
    parent             = var.folder_id
    project_id         = "test-dev"
  }
}
# tftest modules=13 resources=91 e2e
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [network_config](variables.tf#L66) | Shared VPC network configurations to use. If null networks will be created in projects with preconfigured values. | <code title="object&#40;&#123;&#10;  host_project      &#61; string&#10;  network_self_link &#61; string&#10;  subnet_self_link  &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [notebooks](variables.tf#L80) | Vertex AI workbenches to be deployed. Service Account runtime/instances deployed. | <code title="map&#40;object&#40;&#123;&#10;  type             &#61; string&#10;  machine_type     &#61; optional&#40;string, &#34;n1-standard-4&#34;&#41;&#10;  internal_ip_only &#61; optional&#40;bool, true&#41;&#10;  idle_shutdown    &#61; optional&#40;bool, false&#41;&#10;  owner            &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> | ✓ |  |
| [project_config](variables.tf#L107) | Provide 'billing_account_id' value if project creation is needed, uses existing 'project_id' if null. Parent is in 'folders/nnn' or 'organizations/nnn' format. | <code title="object&#40;&#123;&#10;  billing_account_id &#61; optional&#40;string&#41;&#10;  parent             &#61; optional&#40;string&#41;&#10;  project_id         &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [bucket_name](variables.tf#L18) | GCS bucket name to store the Vertex AI artifacts. | <code>string</code> |  | <code>null</code> |
| [dataset_name](variables.tf#L24) | BigQuery Dataset to store the training data. | <code>string</code> |  | <code>null</code> |
| [deletion_protection](variables.tf#L30) | Prevent Terraform from destroying data storage resources (storage buckets, GKE clusters, CloudSQL instances) in this blueprint. When this field is set in Terraform state, a terraform destroy or terraform apply that would delete data storage resources will fail. | <code>bool</code> |  | <code>false</code> |
| [groups](variables.tf#L37) | Name of the groups (name@domain.org) to apply opinionated IAM permissions. | <code title="object&#40;&#123;&#10;  gcp-ml-ds     &#61; optional&#40;string&#41;&#10;  gcp-ml-eng    &#61; optional&#40;string&#41;&#10;  gcp-ml-viewer &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [identity_pool_claims](variables.tf#L48) | Claims to be used by Workload Identity Federation (i.e.: attribute.repository/ORGANIZATION/REPO). If a not null value is provided, then google_iam_workload_identity_pool resource will be created. | <code>string</code> |  | <code>null</code> |
| [labels](variables.tf#L54) | Labels to be assigned at project level. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [location](variables.tf#L60) | Location used for multi-regional resources. | <code>string</code> |  | <code>&#34;us&#34;</code> |
| [prefix](variables.tf#L101) | Prefix used for various resource creation. | <code>string</code> |  | <code>null</code> |
| [region](variables.tf#L121) | Region used for regional resources. | <code>string</code> |  | <code>&#34;us-central1&#34;</code> |
| [repo_name](variables.tf#L127) | Cloud Source Repository name, or null to avoid creating it. | <code>string</code> |  | <code>null</code> |
| [service_encryption_keys](variables.tf#L133) | Cloud KMS to use to encrypt different services. Key location should match service region. | <code title="object&#40;&#123;&#10;  aiplatform    &#61; optional&#40;string&#41;&#10;  bq            &#61; optional&#40;string&#41;&#10;  notebooks     &#61; optional&#40;string&#41;&#10;  secretmanager &#61; optional&#40;string&#41;&#10;  storage       &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [github](outputs.tf#L30) | Github Configuration. |  |
| [notebook](outputs.tf#L35) | Vertex AI notebook ids. |  |
| [project_id](outputs.tf#L43) | Project ID. |  |
<!-- END TFDOC -->