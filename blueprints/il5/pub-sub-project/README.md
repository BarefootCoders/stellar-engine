# Google Pub/Sub Project
This blueprint contains all the necessary Terraform modules to build and deploy a Pub/Sub. This is an asynchronous and scalable messaging service that decouples services producing messages from services processing those messages.

## Introduction
Pub/Sub allows services to communicate asynchronously, and it is used for streamlining analytics and data integration pipelines. The purpose of pub-sub is to load as well as transfer data. Pub-Sub permits latencies on the order of 100 milliseconds. Moreover, it enables the creation of systems of event producers and consumers, referred to as publishers and subscribers. The way that this works is that publishers communicate with subscribers asynchronously by broadcasting events instead of the synchronous remote procedure calls (RPCs). Then, publishers send events to the Pub/Sub service, without regard to how or when these events are to be processed. Afterwards, Pub/Sub delivers events to all the services that react to them. 

## Pre-requisite
1. The Principal (user or group) must have Cloud KMS Admin permission at the GCP Level.
2. Have access to the GCP Project ID
3.  You will need an existing [project](https://cloud.google.com/resource-manager/docs/creating-managing-projects) with [billing enabled](https://cloud.google.com/billing/docs/how-to/modify-project) and a user with the “Project owner” [IAM](https://cloud.google.com/iam) role on that project. __Note__: to grant a user a role, take a look at the [Granting and Revoking Access](https://cloud.google.com/iam/docs/granting-changing-revoking-access#grant-single-role) documentation.


## Disclaimer
- The present GCP Terraform Module in this project is set up and intended to be implemented in an IL5 Impact Level 5 environment using the Assured Workdloads within the Google Cloud Platform (GCP) organization.
- An Assured Workloads and IL5 environments ensures that sensitive data and workloads in GCP adhere to the rigorous security standards mandated by the DoD, making it suitable for government agencies.
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [keyring](variables.tf#L23) | Keyring attributes. | <code title="object&#40;&#123;&#10;  location &#61; string&#10;  name     &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [keys](variables.tf#L31) | Key names and base attributes. Set attributes to null if not needed. | <code title="map&#40;object&#40;&#123;&#10;  destroy_scheduled_duration    &#61; optional&#40;string&#41;&#10;  rotation_period               &#61; optional&#40;string&#41;&#10;  labels                        &#61; optional&#40;map&#40;string&#41;&#41;&#10;  location                      &#61; optional&#40;string, &#34;us-east4&#34;&#41;&#10;  purpose                       &#61; optional&#40;string, &#34;ENCRYPT_DECRYPT&#34;&#41;&#10;  skip_initial_version_creation &#61; optional&#40;bool, false&#41;&#10;  version_template &#61; optional&#40;object&#40;&#123;&#10;    algorithm        &#61; string&#10;    protection_level &#61; optional&#40;string, &#34;HSM&#34;&#41;&#10;  &#125;&#41;&#41;&#10;&#10;&#10;  iam &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    members &#61; list&#40;string&#41;&#10;    role    &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#10;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    member &#61; string&#10;    role   &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;&#10;&#10;&#10;default &#61; &#123;&#10;  &#34;default&#34; &#61; &#123;&#10;    destroy_scheduled_duration    &#61; null&#10;    rotation_period               &#61; null&#10;    labels                        &#61; null&#10;    purpose                       &#61; &#34;ENCRYPT_DECRYPT&#34;&#10;    skip_initial_version_creation &#61; false&#10;    version_template &#61; &#123;&#10;      algorithm        &#61; &#34;GOOGLE_SYMMETRIC_ENCRYPTION&#34;&#10;      protection_level &#61; &#34;HSM&#34;&#10;    &#125;&#10;&#10;&#10;    iam                   &#61; &#123;&#125;&#10;    iam_bindings          &#61; &#123;&#125;&#10;    iam_bindings_additive &#61; &#123;&#125;&#10;  &#125;&#10;&#125;&#10;&#10;&#10;nullable &#61; false">&#8230;</code> | ✓ |  |
| [project](variables.tf#L88) | GCP Project to deploy into. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L93) | Project ID. | <code>string</code> | ✓ |  |
| [publisher_account_id](variables.tf#L98) | Publisher account ID. | <code>string</code> | ✓ |  |
| [publisher_name](variables.tf#L103) | Publisher name. | <code>string</code> | ✓ |  |
| [pubsub_topic](variables.tf#L108) | PubSub topic. | <code>string</code> | ✓ |  |
| [region](variables.tf#L113) | GCP Region to deploy into. | <code>string</code> | ✓ |  |
| [subscriber_account_id](variables.tf#L118) | Subscriber account ID. | <code>string</code> | ✓ |  |
| [subscriber_name](variables.tf#L123) | Subscriber name. | <code>string</code> | ✓ |  |
| [allowed_persistence_regions](variables.tf#L17) | The allowed persistence regions for the Pub/Sub topic. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#34;us-east4&#34;&#93;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [publisher_service_account_email](outputs.tf#L17) | The email of the publisher service account. |  |
| [subscriber_service_account_email](outputs.tf#L22) | The email of the subscriber service account. |  |
<!-- END TFDOC -->
## How to deploy the Terraform Code. The Deployment Steps
You should see this README and some terraform files.
1. Update the Variables in the variables.tf 
2. There is a sample ```terraform.tfvars.sample``` available as well.
3. Although each use case is somehow built around the previous one they are self-contained so you can deploy any of them at your will. The usual terraform commands will do the work:

```bash
terraform init
terraform plan
terraform apply
```

It will take a few minutes. When complete, you should see an output stating the command completed successfully, a list of the created resources.

Apply complete! Resources: 1 added, 0 changed, 1 destroyed.

Outputs:

publisher_service_account_email = "publisher@dev-repo.iam.gserviceaccount.com"
subscriber_service_account_email = "subscriber@dev-repo.iam.gserviceaccount.com"

