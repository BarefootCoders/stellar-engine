# Google Compute Shielded VM Project
This blueprint contains all the necessary Terraform modules to build and deploy a Shielded VMs are virtual machines (VMs) on Google Cloud

## Introduction
Shielded VMs are virtual machines (VMs) on Google Cloud hardened by a set of security controls that help defend against rootkits and bootkits. Using Shielded VMs helps protect enterprise workloads from threats like remote attacks, privilege escalation, and malicious insiders. Shielded VMs leverage advanced platform security capabilities such as secure and measured boot, a virtual trusted platform module (vTPM), UEFI firmware, and integrity monitoring.

1. Enforce the Best Practices for the Shielded VM to be Enable Secure Boot, Enable VTPM, Monitoring
```
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true

```
2. Enable the Customer-Managed Encryption Keys (CMEK) Cloud KMS for Google Compute Engine and Disk

3.  The IL5 Requirements as of the creation of the project the region of deployment to US Only for example in us-east4 and us-central1

4. __Important Note__: The project is scoped around the computer engine shielded VM, and in order to deploy the code, there is a dependency on the Google VPC module (VPC and subnet), and the code uses the Google VPC module along with the Google KMS module. As per requirements, The CFF stages are supposed to set that up for new projects.


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
| [allowed_firewall_ports](variables.tf#L17) | The list of the Allowed Ports. | <code>list&#40;any&#41;</code> | ✓ |  |
| [compute_service_account_id](variables.tf#L23) | The Service Account for Compute Engine. | <code>string</code> | ✓ |  |
| [ip_cidr_range](variables.tf#L48) | The IP CIDR range for the VPC. | <code>string</code> | ✓ |  |
| [keyring](variables.tf#L54) | Keyring attributes. | <code title="object&#40;&#123;&#10;  location &#61; string&#10;  name     &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [project_id](variables.tf#L127) | Project ID. | <code>string</code> | ✓ |  |
| [source_ranges_allowed](variables.tf#L132) | The List of the source IP CIDR range allowed to connect to the Shieled Compute VM. | <code>list&#40;any&#41;</code> | ✓ |  |
| [subnet_name](variables.tf#L138) | The name of the subnet. | <code>string</code> | ✓ |  |
| [vpc_name](variables.tf#L144) | The name of the VPC. | <code>string</code> | ✓ |  |
| [disksize](variables.tf#L29) | Provide the Size of the size in GB. | <code>number</code> |  | <code>40</code> |
| [instance_name](variables.tf#L35) | Provide the name of the Compute Instance. | <code>string</code> |  | <code>&#34;shieled-vm-inst&#34;</code> |
| [instance_type](variables.tf#L41) | The Machine Type for the Shielded Compute VM. | <code>string</code> |  | <code>&#34;e2-micro&#34;</code> |
| [keys](variables.tf#L68) | Key names and base attributes. Set attributes to null if not needed. | <code title="map&#40;object&#40;&#123;&#10;  destroy_scheduled_duration    &#61; optional&#40;string&#41;&#10;  rotation_period               &#61; optional&#40;string&#41;&#10;  labels                        &#61; optional&#40;map&#40;string&#41;&#41;&#10;  purpose                       &#61; optional&#40;string, &#34;ENCRYPT_DECRYPT&#34;&#41;&#10;  skip_initial_version_creation &#61; optional&#40;bool, false&#41;&#10;  version_template &#61; optional&#40;object&#40;&#123;&#10;    algorithm        &#61; string&#10;    protection_level &#61; optional&#40;string, &#34;HSM&#34;&#41;&#10;  &#125;&#41;&#41;&#10;&#10;&#10;  iam &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    members &#61; list&#40;string&#41;&#10;    role    &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    member &#61; string&#10;    role   &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code title="&#123;&#10;  &#34;default&#34; &#61; &#123;&#10;    destroy_scheduled_duration    &#61; null&#10;    rotation_period               &#61; null&#10;    labels                        &#61; null&#10;    purpose                       &#61; &#34;ENCRYPT_DECRYPT&#34;&#10;    skip_initial_version_creation &#61; false&#10;    version_template &#61; &#123;&#10;      algorithm        &#61; &#34;GOOGLE_SYMMETRIC_ENCRYPTION&#34;&#10;      protection_level &#61; &#34;HSM&#34;&#10;    &#125;&#10;&#10;&#10;    iam                   &#61; &#123;&#125;&#10;    iam_bindings          &#61; &#123;&#125;&#10;    iam_bindings_additive &#61; &#123;&#125;&#10;  &#125;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [location](variables.tf#L121) | Location of the Shielded Compute VM. | <code>string</code> |  | <code>&#34;us-east4&#34;</code> |
| [zone](variables.tf#L150) | Zone of the Shielded Compute VM us-east4-c , us-east4-a, us-east4-b. | <code>string</code> |  | <code>&#34;us-east4-c&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [keyring-id](outputs.tf#L17) | Fully qualified keyring id. |  |
| [keyring-location](outputs.tf#L22) | Keyring location. |  |
| [keyring-name](outputs.tf#L27) | Keyring name. |  |
| [keyring-resource](outputs.tf#L32) | Keyring resource. |  |
| [keyrings-keys](outputs.tf#L37) | Key resources. |  |
| [shielded-vm-instance](outputs.tf#L42) | Instance resource. | ✓ |
| [shielded-vm-instance-id](outputs.tf#L48) | Fully qualified instance id. |  |
| [shielded-vm-internal_ip](outputs.tf#L53) | Instance main interface internal IP address. |  |
| [shielded-vm-internal_ips](outputs.tf#L58) | Instance interfaces internal IP addresses. |  |
| [shielded-vm-service_account](outputs.tf#L63) | Service account resource. |  |
| [shielded-vm-service_account_email](outputs.tf#L68) | Service account email. |  |
<!-- END TFDOC -->
