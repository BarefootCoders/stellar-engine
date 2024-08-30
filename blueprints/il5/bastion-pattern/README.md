
## Introduction Bastion Pattern (Bastion Pattern Project)
Bastions simplify secuirty administration. The internal network can be configured to block all the internet-bound traffic. It only allows SSH communications with the bastion host. The bastion pattern grants authorized users access access to a priate network from an external network such as internet. By following these steps, you will securely access multiple web services via the bastion host using port forwarding. This README section explains how to set up port forwarding for multiple ports and access the corresponding web services.
1. The IAM Permissions and Roles ```roles/cloudkms.cryptoKeyEncrypterDecrypter``` is assigned
Obtains access credentials for your user account via a web-based authorization flow. When this command completes successfully, it sets the active account in the current configuration to the account specified.

## Pre-requisite for Bastion Pattern Project (Bastion Pattern Project)
1. Have access to the GCP Project ID
2. You will need an existing [project](https://cloud.google.com/resource-manager/docs/creating-managing-projects) with [billing enabled](https://cloud.google.com/billing/docs/how-to/modify-project) and a user with the “Project owner” [IAM](https://cloud.google.com/iam) role on that project.
3. __Note__: to grant a user a role, take a look at the [Granting and Revoking Access](https://cloud.google.com/iam/docs/granting-changing-revoking-access#grant-single-role) documentation.

## Disclaimer
- The present GCP Terraform Module in this project is set up and intended to be implemented in an IL5 Impact Level 5 environment using the Assured Workdloads within the Google Cloud Platform (GCP) organization.
- An Assured Workloads and IL5 environments ensures that sensitive data and workloads in GCP adhere to the rigorous security standards mandated by the DoD, making it suitable for government agencies.

## How can you connect to the Bastion? 
To access the web portal through the bastion host, follow these steps:

1. **Set the Active Project** :
```bash
gcloud config set project set project <your-project-id>
```

This command will configure the gcloud CLI to utilize the specified project for every subsequent command. Thus, you should replace your project ID of your project with the ID of your Google Cloud Platform project. 

2. **SSH into the Bastion Host via Port Forwarding**:
Use the following command to create an SSH tunnel through the bastion host and set up port forwarding for multiple ports:
```
gcloud compute ssh <your-bastion-host-name> --zone <your-zone> --tunnel-through-iap --project <your-project-id> -- \
-L 8443:<ip-of-bastion>:<remote-port1> \
-L 8444:<ip-of-bastion>:<remote-port2>\
-L 8445:<ip-of-bastion>::<remote-port3>
```

For example, if you need to forward local ports 8443, 8444, and 8445 to remote ports 443, 8443, and 8444 on <ip-of-bastion>, respectively, you would use:
```bash
gcloud compute ssh management-bastion --zone us-east4-a --tunnel-through-iap --project example-prod-iac-core-0 -- \
-L 8443:192.168.1.10:443 \
-L 8444:192.168.1.10:8443 \
-L 8445:192.168.1.10:8444
```

In this example:
- -L 8443:192.168.1.10:443: Forwards local port 8443 to port 443 on the remote server.
- -L 8444:192.168.1.10:8443: Forwards local port 8444 to port 8443 on the remote server.
- -L 8445:192.168.1.10:8444: Forwards local port 8445 to port 8444 on the remote server.

3. **Access the Web Portals**:
Once the SSH tunnel is established, you can access the web services by navigating to these websites in your web browser:
- https://localhost:8443 for the service on remote port 443.
- https://localhost:8444 for the service on remote port 8443.
- https://localhost:8445 for the service on remote port 8444.
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [allowed_firewall_ports](variables.tf#L17) | The allowed ports for the firewall. | <code>list&#40;string&#41;</code> | ✓ |  |
| [allowed_source_ranges](variables.tf#L22) | These are the allowed source ranges. | <code>list&#40;string&#41;</code> | ✓ |  |
| [compute_service_account_id](variables.tf#L27) | This is the compute service account id. | <code>string</code> | ✓ |  |
| [disk_name](variables.tf#L32) | This is the disk name. | <code>string</code> | ✓ |  |
| [image](variables.tf#L37) | Disk image. | <code>string</code> | ✓ |  |
| [instance_name](variables.tf#L42) | This is the instance name. | <code>string</code> | ✓ |  |
| [keyring](variables.tf#L53) | Keyring attributes. | <code title="object&#40;&#123;&#10;  location &#61; string&#10;  name     &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [keys](variables.tf#L61) | Key names and base attributes. Set attributes to null if not needed. | <code title="map&#40;object&#40;&#123;&#10;  destroy_scheduled_duration    &#61; optional&#40;string&#41;&#10;  rotation_period               &#61; optional&#40;string&#41;&#10;  labels                        &#61; optional&#40;map&#40;string&#41;&#41;&#10;  purpose                       &#61; optional&#40;string, &#34;ENCRYPT_DECRYPT&#34;&#41;&#10;  skip_initial_version_creation &#61; optional&#40;bool, false&#41;&#10;  version_template &#61; optional&#40;object&#40;&#123;&#10;    algorithm        &#61; string&#10;    protection_level &#61; optional&#40;string, &#34;hsm&#34;&#41;&#10;  &#125;&#41;&#41;&#10;&#10;&#10;  iam &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    members &#61; list&#40;string&#41;&#10;    role    &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#10;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    member &#61; string&#10;    role   &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;&#10;&#10;&#10;default &#61; &#123;&#10;  &#34;bastion&#34; &#61; &#123;&#10;    destroy_scheduled_duration    &#61; null&#10;    rotation_period               &#61; null&#10;    labels                        &#61; null&#10;    purpose                       &#61; &#34;ENCRYPT_DECRYPT&#34;&#10;    skip_initial_version_creation &#61; false&#10;    version_template &#61; &#123;&#10;      algorithm        &#61; &#34;GOOGLE_SYMMETRIC_ENCRYPTION&#34;&#10;      protection_level &#61; &#34;HSM&#34;&#10;    &#125;&#10;&#10;&#10;    iam                   &#61; &#123;&#125;&#10;    iam_bindings          &#61; &#123;&#125;&#10;    iam_bindings_additive &#61; &#123;&#125;&#10;  &#125;&#10;&#125;&#10;&#10;&#10;nullable &#61; false">&#8230;</code> | ✓ |  |
| [my_subnet](variables.tf#L117) | Subnet to use. | <code>string</code> | ✓ |  |
| [my_vpc](variables.tf#L122) | VPC to use. | <code>string</code> | ✓ |  |
| [project](variables.tf#L127) | GCP Project to deploy into. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L133) | This is the ID of project. | <code>string</code> | ✓ |  |
| [region](variables.tf#L138) | GCP Region to deploy into. | <code>string</code> | ✓ |  |
| [zone](variables.tf#L143) | This is the zone of the instance. | <code>string</code> | ✓ |  |
| [instance_type](variables.tf#L47) | Instance type. | <code>string</code> |  | <code>&#34;e2-small&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [compute_service_account_email](outputs.tf#L17) | The email of the compute service account. |  |
| [subnet_self_link](outputs.tf#L22) | The self link of the subnet. |  |
| [vpc_self_link](outputs.tf#L27) | The self link of the VPC. |  |
<!-- END TFDOC -->
## How to deploy the Terraform Code. The Deployment Steps
You should see this README and some terraform files.
1. Update the Variables in the variables.tf and also the properties within the keys variables. For reference update the following variables and associated properties
2. There is a sample ```terraform.tfvars.sample``` available as well.
3. Although each use case is somehow built around the previous one they are self-contained so you can deploy any of them at your will. The usual terraform commands will do the work:

```bash
terraform init
terraform plan
terraform apply
```

It will take a few minutes. When complete, you should see an output stating the command completed successfully, a list of the created resources.

```bash
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

internal_ip = "10.0.0.2"
kms_key_self_link = "projects/my-repository/locations/us-east4/keyRings/my-keyring/cryptoKeys/default"
vpc_network = "https://www.googleapis.com/compute/v1/projects/my-repository-dev/global/networks/prod-mgmt-0"

```