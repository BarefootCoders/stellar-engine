# Google Compute Engine VM with Security Onion 
Security Onion is a  open-source software suite designed for network security monitoring (NSM) and intrusion detection (IDS). It is a solution for monitoring, alerting, and defending enterprise networks.
This  Blue project provides a basic setup for deploying Security Onion on Google Compute Engine using Terraform. Adjustments may be necessary based on the organization's security policies and best practices.

 ## Pre-requisite
1. The Principal (user or group) must have permission at GCP Level for deployment of Cloud KMS (Admin), Able to Deploy a Google VPC, Able to create GCP Compute Engine  VM.
2. Have access to the GCP Project ID
3.  You will need an existing [project](https://cloud.google.com/resource-manager/docs/creating-managing-projects) with [billing enabled](https://cloud.google.com/billing/docs/how-to/modify-project) and a user with the “Project owner” [IAM](https://cloud.google.com/iam) role on that project. __Note__: To grant a user a role, take a look at the [Granting and Revoking Access](https://cloud.google.com/iam/docs/granting-changing-revoking-access#grant-single-role) documentation.
4. __Important Note__: The project is scoped around the computer engine VM, and in order to deploy the code, there is a dependency on the Google VPC module (VPC and subnet), and the code uses the Google VPC module along with the Google KMS module. As per requirements, The CFF stages are supposed to set that up for new projects. 

## Security Onion Specification
- Security Onion only supports x86-64 architecture (standard Intel or AMD 64-bit processors). The Minimum Specification is available at the official page [Specification Requirements](https://docs.securityonion.net/en/2.4/hardware.html#hardware)
- The project is doing a standalone deployment, the manager components and the sensor components all run on a single box of Google Compute Engine (GCE). For standalone there is a need for minimum 16GB RAM, 4 CPU cores, and 200GB storage. 
- Security Onion can be deployed in various architectures, including standalone, distributed, and cloud-based deployments. The hardware requirements may vary based on the chosen architecture.

## Disclaimer
- The present GCP Terraform Module in this project is set up and intended to be implemented in an IL5 Impact Level 5 environment using the Assured Workdloads within the Google Cloud Platform (GCP) organization.

## How to deploy the Terraform Code. The Deployment Steps
You should see this README and some terraform files.
1. Create an ```terraform.tfvars```. Copy the content from the  sample ```terraform.tfvars.sample```. Update the values in the ```terraform.tfvars```
2. Although each use case is somehow built around the previous one they are self-contained so you can deploy any of them at your will. The usual terraform commands will do the work:

```bash
terraform init
terraform plan
terraform apply
```
It will take a few minutes. When complete, you should see an output stating the command completed successfully, a list of the created resources.

## Verification of a successful Terraform/Infrastructure deployment?
- Go to the Google Compute Engine (GCE) in the GCP Console. Select the VM instance.
![Google Compute Engine](./images/ce1.png?raw=true "Google Compute Engine")
- Click on the Instance Name inside the Google Compute Engine Panel
![Google Compute Engine so](./images/ce2.png?raw=true "Google Compute Engine so")

## Configuration of the Security Onion 
- After the Terraform deployment of there are installation steps needed to configure the Security Onion. 
- The step-by-step configuration for security Onion is exaplined in setup documentation 
[Security Onion Configuration Documentation](./setup-docs/README.md)

## Cleanup
Once the project is deployed, to ensure clean up, please apply following command.
```bash
terraform destory
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [auto_delete](variables.tf#L17) | Persistent Disk auto delete options. | <code>bool</code> | ✓ |  |
| [boot_disk_image](variables.tf#L23) | The Name of the Disk Image  for the Compute Engine VM. | <code>string</code> | ✓ |  |
| [boot_disk_size_gb](variables.tf#L29) | The Size of the Boot Disk in GB. | <code>number</code> | ✓ |  |
| [compute_service_account_id](variables.tf#L35) | The Service Account for Compute Engine. Provide the name to be given to the Computer Engine Service Account. | <code>string</code> | ✓ |  |
| [email](variables.tf#L41) | Email address of the user. | <code>string</code> | ✓ |  |
| [instance_name](variables.tf#L47) | The name of the compute engine instance. | <code>string</code> | ✓ |  |
| [instance_type](variables.tf#L53) | The Machine Type for the Compute Engine VM. | <code>string</code> | ✓ |  |
| [keyring](variables.tf#L59) | Keyring attributes. | <code title="object&#40;&#123;&#10;  location &#61; string&#10;  name     &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [nat_a_name](variables.tf#L132) | The NAT Name a. | <code>string</code> | ✓ |  |
| [nat_b_name](variables.tf#L138) | The NAT Name b. | <code>string</code> | ✓ |  |
| [project](variables.tf#L144) | GCP Project to deploy into. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L149) | Project ID. | <code>string</code> | ✓ |  |
| [region](variables.tf#L155) | GCP Region to deploy into. | <code>string</code> | ✓ |  |
| [source_ranges_cidrs](variables.tf#L160) | The CIDR source ranges. | <code>list&#40;string&#41;</code> | ✓ |  |
| [subnet_a_ip_cidr](variables.tf#L166) | The Subnet a IP CIDR CIDR. | <code>string</code> | ✓ |  |
| [subnet_a_name](variables.tf#L172) | The Subnet A Name. | <code>string</code> | ✓ |  |
| [subnet_a_secondary_ip_cidr_1](variables.tf#L178) | The Subnet a Seoncary IP CIDR for one. | <code>string</code> | ✓ |  |
| [subnet_a_secondary_ip_cidr_2](variables.tf#L184) | The Subnet a Seoncary IP CIDR for two. | <code>string</code> | ✓ |  |
| [subnet_b_ip_cidr](variables.tf#L190) | The Subnet a IP CIDR CIDR. | <code>string</code> | ✓ |  |
| [subnet_b_name](variables.tf#L196) | The Subnet B Name. | <code>string</code> | ✓ |  |
| [subnet_b_secondary_ip_cidr_1](variables.tf#L202) | The Subnet a Seoncary IP CIDR for one. | <code>string</code> | ✓ |  |
| [subnet_b_secondary_ip_cidr_2](variables.tf#L208) | The Subnet a Seoncary IP CIDR for two. | <code>string</code> | ✓ |  |
| [vpc_a_name](variables.tf#L214) | The VPC A name. | <code>string</code> | ✓ |  |
| [vpc_b_name](variables.tf#L220) | The VPC B name. | <code>string</code> | ✓ |  |
| [zone](variables.tf#L226) | Zone of the Compute Engine VM us-east4-c , us-east4-a, us-east4-b. | <code>string</code> | ✓ |  |
| [keys](variables.tf#L73) | Key names and base attributes. Set attributes to null if not needed. | <code title="map&#40;object&#40;&#123;&#10;  destroy_scheduled_duration    &#61; optional&#40;string&#41;&#10;  rotation_period               &#61; optional&#40;string&#41;&#10;  labels                        &#61; optional&#40;map&#40;string&#41;&#41;&#10;  purpose                       &#61; optional&#40;string, &#34;ENCRYPT_DECRYPT&#34;&#41;&#10;  skip_initial_version_creation &#61; optional&#40;bool, false&#41;&#10;  version_template &#61; optional&#40;object&#40;&#123;&#10;    algorithm        &#61; string&#10;    protection_level &#61; optional&#40;string, &#34;SOFTWARE&#34;&#41;&#10;  &#125;&#41;&#41;&#10;&#10;&#10;  iam &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    members &#61; list&#40;string&#41;&#10;    role    &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    member &#61; string&#10;    role   &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code title="&#123;&#10;  &#34;default&#34; &#61; &#123;&#10;    destroy_scheduled_duration    &#61; null&#10;    rotation_period               &#61; null&#10;    labels                        &#61; null&#10;    purpose                       &#61; &#34;ENCRYPT_DECRYPT&#34;&#10;    skip_initial_version_creation &#61; false&#10;    version_template &#61; &#123;&#10;      algorithm        &#61; &#34;GOOGLE_SYMMETRIC_ENCRYPTION&#34;&#10;      protection_level &#61; &#34;SOFTWARE&#34;&#10;    &#125;&#10;&#10;&#10;    iam                   &#61; &#123;&#125;&#10;    iam_bindings          &#61; &#123;&#125;&#10;    iam_bindings_additive &#61; &#123;&#125;&#10;  &#125;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [location](variables.tf#L126) | Location of the Compute Engine VM. | <code>string</code> |  | <code>&#34;us-east4&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [compute-engine-vm-instance](outputs.tf#L17) | Instance resource. | ✓ |
| [compute-engine-vm-instance-id](outputs.tf#L23) | Fully qualified instance id. |  |
| [compute-engine-vm-internal_ip](outputs.tf#L28) | Instance main interface internal IP address. |  |
| [compute-engine-vm-internal_ips](outputs.tf#L33) | Instance interfaces internal IP addresses. |  |
| [compute-engine-vm-service_account](outputs.tf#L38) | Service account resource. |  |
| [compute-engine-vm-service_account_email](outputs.tf#L43) | Service account email. |  |
| [keyring-id](outputs.tf#L48) | Fully qualified keyring id. |  |
| [keyring-location](outputs.tf#L53) | Keyring location. |  |
| [keyring-name](outputs.tf#L58) | Keyring name. |  |
| [keyring-resource](outputs.tf#L63) | Keyring resource. |  |
| [keyrings-keys](outputs.tf#L68) | Key resources. |  |
| [nat-id-a](outputs.tf#L73) | Fully qualified NAT (router) id. |  |
| [nat-id-b](outputs.tf#L78) | Fully qualified NAT (router) id. |  |
| [nat-name-a](outputs.tf#L83) | Name of the Cloud NAT. |  |
| [nat-name-b](outputs.tf#L88) | Name of the Cloud NAT. |  |
| [vpc-network-a](outputs.tf#L93) | Network resource. |  |
| [vpc-network-attachment-ids-a](outputs.tf#L98) | IDs of network attachments. |  |
| [vpc-network-attachment-ids-b](outputs.tf#L103) | IDs of network attachments. |  |
| [vpc-network-b](outputs.tf#L108) | Network resource. |  |
| [vpc-network-self-link-a](outputs.tf#L113) | Network self link. |  |
| [vpc-network-self-link-b](outputs.tf#L118) | Network self link. |  |
| [vpc-subnet-ids-a](outputs.tf#L123) | Map of subnet IDs keyed by name. |  |
| [vpc-subnet-ids-b](outputs.tf#L128) | Map of subnet IDs keyed by name. |  |
| [vpc-subnet-ips-a](outputs.tf#L133) | Map of subnet address ranges keyed by name. |  |
| [vpc-subnet-ips-b](outputs.tf#L138) | Map of subnet address ranges keyed by name. |  |
<!-- END TFDOC -->
