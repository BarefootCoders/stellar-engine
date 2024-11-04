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
4. Region of deployment to US Only  for example in us-east4 and us-central1

## Pre-requisite
1. The Principal (user or group) must have Cloud KMS Admin permission at the GCP Level.

## Disclaimer
- The present GCP Terraform Module in this project is set up and intended to be implemented in either a FedRamp-high or IL5 Impact Level 5 environment using the Assured Workdloads within the Google Cloud Platform (GCP) organization.
- Assured Workloads in both environments ensures that sensitive data and workloads in GCP adhere to the rigorous security standards mandated by the DoD, making it suitable for government agencies.

## Deployment Steps
You should see this README and some terraform files.
1.  Update the Variables in the variables.tf that are marked as "# TODO: Update"
2. The list of variables to be updated are project_id, keyring, prefix, name, location, email


```tfvars
project_id = "[your-project_id]"
```

may become

```tfvars
project_id = "YOUR-PROJECT-ID-123"
```

The Location

 ```tfvars
location = "us-east4"
```


Although each use case is somehow built around the previous one they are self-contained so you can deploy any of them at will.

3. The usual terraform commands will do the work:

```bash
terraform init
terraform plan
terraform apply
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [email](variables.tf#L24) | Email address of the user. | <code>string</code> | ✓ |  |
| [keyring](variables.tf#L29) | Keyring attributes. | <code title="object&#40;&#123;&#10;  location &#61; string&#10;  name     &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [name](variables.tf#L96) | Bucket name suffix. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L111) | Project ID. | <code>string</code> | ✓ |  |
| [retention_policy](variables.tf#L126) | Retention policy. | <code title="object&#40;&#123;&#10;  is_locked        &#61; bool&#10;  retention_period &#61; number&#10;&#125;&#41;&#10;&#10;&#10;default &#61; &#123;&#10;  is_locked        &#61; false &#35; Change to true if storing logs here for CIS Compliance Benchmark 2.3&#10;  retention_period &#61; 7776000&#10;&#125;">object&#40;&#123;&#8230;&#125;</code> | ✓ |  |
| [autoclass](variables.tf#L18) | Enable autoclass to automatically transition objects to appropriate storage classes based on their access pattern. If set to true, storage_class must be set to STANDARD. When set to true, All objects added to the bucket begin in Standard storage, even if a different storage class is specified in the request. | <code>bool</code> |  | <code>true</code> |
| [keys](variables.tf#L37) | Key names and base attributes. Set attributes to null if not needed. | <code title="map&#40;object&#40;&#123;&#10;  destroy_scheduled_duration    &#61; optional&#40;string&#41;&#10;  rotation_period               &#61; optional&#40;string, &#34;7776000s&#34;&#41; &#35; Compliant with CIS IAM 1.10&#10;  labels                        &#61; optional&#40;map&#40;string&#41;&#41;&#10;  purpose                       &#61; optional&#40;string, &#34;ENCRYPT_DECRYPT&#34;&#41;&#10;  skip_initial_version_creation &#61; optional&#40;bool, false&#41;&#10;  version_template &#61; optional&#40;object&#40;&#123;&#10;    algorithm        &#61; string&#10;    protection_level &#61; optional&#40;string, &#34;HSM&#34;&#41;&#10;  &#125;&#41;&#41;&#10;&#10;&#10;  iam &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    members &#61; list&#40;string&#41;&#10;    role    &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    member &#61; string&#10;    role   &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code title="&#123;&#10;  &#34;default&#34; &#61; &#123;&#10;    destroy_scheduled_duration    &#61; null&#10;    rotation_period               &#61; null&#10;    labels                        &#61; null&#10;    purpose                       &#61; &#34;ENCRYPT_DECRYPT&#34;&#10;    skip_initial_version_creation &#61; false&#10;    version_template &#61; &#123;&#10;      algorithm        &#61; &#34;GOOGLE_SYMMETRIC_ENCRYPTION&#34;&#10;      protection_level &#61; &#34;HSM&#34;&#10;    &#125;&#10;&#10;&#10;    iam                   &#61; &#123;&#125;&#10;    iam_bindings          &#61; &#123;&#125;&#10;    iam_bindings_additive &#61; &#123;&#125;&#10;  &#125;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [location](variables.tf#L90) | Bucket location. | <code>string</code> |  | <code>&#34;us-east4&#34;</code> |
| [prefix](variables.tf#L101) | Optional prefix used to generate the bucket name. | <code>string</code> |  | <code>&#34;string&#34;</code> |
| [public_access_prevention](variables.tf#L116) | This provides the ability to toggle Public Access Prevention for the GCS Storage bucket. By settng this variable to enforced, the CIS Benchmark 5.1 compliance control is satsified. | <code>string</code> |  | <code>&#34;enforced&#34;</code> |
| [storage_class](variables.tf#L139) | Bucket storage class. | <code>string</code> |  | <code>&#34;STANDARD&#34;</code> |
| [uniform_bucket_level_access](variables.tf#L149) | This provides the ability to toggle Uniform Bucket Level Acess for the GCS Storage bucket. By settng this variable to true, the CIS Benchmark 5.2 compliance control is satsified. | <code>bool</code> |  | <code>true</code> |
<!-- END TFDOC -->
