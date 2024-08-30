# Google Compute Engine VM with Persistent Disk Project
This blueprint contains all the necessary Terraform modules to build and deploy a Compute Engine VM (virtual machines VMs on Google Cloud) attached to a persistent disk having encryption using the Cloud Key Management Service (KMS).

## Introduction
Compute Engine is an Infrastructure-as-a-Service product offering flexible, self-managed virtual machines (VMs) hosted on Google's infrastructure.  Persistent Disk is Google's local durable storage service, fully integrated with Google Cloud products, Compute Engine. Persistent Disk volumes are durable network storage devices that your virtual machine (VM) instances can access like physical disks in a desktop or a server.  Persistent Disk remains encrypted usng the Customer-Managed Encryption Keys (CMEK) Cloud KMS.

1. Create and Encrypt a Google Cloud Persistent Disk Using Cloud KMS
2. Enable the Customer-Managed Encryption Keys (CMEK) Cloud KMS for Google Compute Engine and Disk
3.  The IL5 Requirements as of the creation of the project the region of deployment to US Only for example in us-east4 and us-central1

4. __Important Note__: The project is scoped around the computer engine VM, and in order to deploy the code, there is a dependency on the Google VPC module (VPC and subnet), and the code uses the Google VPC module along with the Google KMS module. As per requirements, The CFF stages are supposed to set that up for new projects.

## Pre-requisite
1. The Principal (user or group) must have Cloud KMS Admin permission at the GCP Level.
2. Have access to the GCP Project ID
3.  You will need an existing [project](https://cloud.google.com/resource-manager/docs/creating-managing-projects) with [billing enabled](https://cloud.google.com/billing/docs/how-to/modify-project) and a user with the “Project owner” [IAM](https://cloud.google.com/iam) role on that project. __Note__: to grant a user a role, take a look at the [Granting and Revoking Access](https://cloud.google.com/iam/docs/granting-changing-revoking-access#grant-single-role) documentation.
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [allowed_firewall_ports](variables.tf#L17) | The list of the Allowed Ports. | <code>list&#40;any&#41;</code> | ✓ |  |
| [auto_delete](variables.tf#L23) | Persistent Disk auto delete options. | <code>bool</code> | ✓ |  |
| [compute_service_account_id](variables.tf#L29) | The Service Account for Compute Engine. | <code>string</code> | ✓ |  |
| [email](variables.tf#L35) | Email address of the user. | <code>string</code> | ✓ |  |
| [instance_name](variables.tf#L41) | Provide the name of the Compute Instance. | <code>string</code> | ✓ |  |
| [ip_cidr_range](variables.tf#L54) | The IP CIDR range for the VPC. | <code>string</code> | ✓ |  |
| [keyring](variables.tf#L60) | Keyring attributes. | <code title="object&#40;&#123;&#10;  location &#61; string&#10;  name     &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [project](variables.tf#L134) | GCP Project to deploy into. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L139) | Project ID. | <code>string</code> | ✓ |  |
| [region](variables.tf#L145) | GCP Region to deploy into. | <code>string</code> | ✓ |  |
| [source_ranges_allowed](variables.tf#L150) | The List of the source IP CIDR range allowed to connect to the Compute Engine VM. | <code>list&#40;any&#41;</code> | ✓ |  |
| [instance_type](variables.tf#L47) | The Machine Type for the Compute Engine VM. | <code>string</code> |  | <code>&#34;e2-micro&#34;</code> |
| [keys](variables.tf#L74) | Key names and base attributes. Set attributes to null if not needed. | <code title="map&#40;object&#40;&#123;&#10;  destroy_scheduled_duration    &#61; optional&#40;string&#41;&#10;  rotation_period               &#61; optional&#40;string&#41;&#10;  labels                        &#61; optional&#40;map&#40;string&#41;&#41;&#10;  purpose                       &#61; optional&#40;string, &#34;ENCRYPT_DECRYPT&#34;&#41;&#10;  skip_initial_version_creation &#61; optional&#40;bool, false&#41;&#10;  version_template &#61; optional&#40;object&#40;&#123;&#10;    algorithm        &#61; string&#10;    protection_level &#61; optional&#40;string, &#34;HSM&#34;&#41;&#10;  &#125;&#41;&#41;&#10;&#10;&#10;  iam &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    members &#61; list&#40;string&#41;&#10;    role    &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    member &#61; string&#10;    role   &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code title="&#123;&#10;  &#34;default&#34; &#61; &#123;&#10;    destroy_scheduled_duration    &#61; null&#10;    rotation_period               &#61; null&#10;    labels                        &#61; null&#10;    purpose                       &#61; &#34;ENCRYPT_DECRYPT&#34;&#10;    skip_initial_version_creation &#61; false&#10;    version_template &#61; &#123;&#10;      algorithm        &#61; &#34;GOOGLE_SYMMETRIC_ENCRYPTION&#34;&#10;      protection_level &#61; &#34;HSM&#34;&#10;    &#125;&#10;&#10;&#10;    iam                   &#61; &#123;&#125;&#10;    iam_bindings          &#61; &#123;&#125;&#10;    iam_bindings_additive &#61; &#123;&#125;&#10;  &#125;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [location](variables.tf#L127) | Location of the Compute Engine VM. | <code>string</code> |  | <code>&#34;us-east4&#34;</code> |
| [zone](variables.tf#L156) | Zone of the Compute Engine VM us-east4-c , us-east4-a, us-east4-b. | <code>string</code> |  | <code>&#34;us-east4-c&#34;</code> |

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
<!-- END TFDOC -->
## Disclaimer
- The present GCP Terraform Module in this project is set up and intended to be implemented in an IL5 Impact Level 5 environment using the Assured Workdloads within the Google Cloud Platform (GCP) organization.
- An Assured Workloads and IL5 environments ensures that sensitive data and workloads in GCP adhere to the rigorous security standards mandated by the DoD, making it suitable for government agencies.

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

The Output will look like following
```
Apply complete! Resources: 13 added, 0 changed, 0 destroyed.

Outputs:

compute-engine-vm-instance = <sensitive>
compute-engine-vm-instance-id = "projects/project-name/zones/gcp-zone/instances/instance-name"
compute-engine-vm-internal_ip = "some-ip-address"
compute-engine-vm-internal_ips = [
  "some-ip-address",
]
compute-engine-vm-service_account_email = "compute@project-name.iam.gserviceaccount.com"
keyring-id = "projects/project-name/locations/gcp-region/keyRings/keyring-name"
keyring-location = "gcp-region"
keyring-name = "keyring-name"
keyring-resource = {
  "id" = "projects/project-name/locations/gcp-region/keyRings/keyring-name"
  "location" = "gcp-region"
  "name" = "keyring-name"
  "project" = "project-name"
  "timeouts" = null /* object */
}
keyrings-keys = {
  "default" = {
    "crypto_key_backend" = ""
    "destroy_scheduled_duration" = "2592000s"
    "effective_labels" = tomap({})
    "id" = "projects/project-name/locations/gcp-region/keyRings/keyring-name/cryptoKeys/default"
    "import_only" = false
    "key_ring" = "projects/project-name/locations/gcp-region/keyRings/keyring-name"
    "labels" = tomap(null) /* of string */
    "name" = "default"
    "primary" = tolist([
      {
        "name" = "projects/project-name/locations/gcp-region/keyRings/keyring-name/cryptoKeys/default/cryptoKeyVersions/1"
        "state" = "ENABLED"
      },
    ])
    "purpose" = "ENCRYPT_DECRYPT"
    "rotation_period" = ""
    "skip_initial_version_creation" = false
    "terraform_labels" = tomap({})
    "timeouts" = null /* object */
    "version_template" = tolist([
      {
        "algorithm" = "GOOGLE_SYMMETRIC_ENCRYPTION"
        "protection_level" = "HSM"
      },
    ])
  }
}

```
## Verification of a successful deployment?

- Go to the Compute Engine in the GCP Console. Select the VM. Check the Presistent Disk Encryption
![GCP Compute Engine Instance Presistent Disk Encryption](./images/vm-disk-1.png?raw=true "GCP Compute Engine Instance Presistent Disk Encryption")
