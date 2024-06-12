
## Introduction Bastion Pattern (Bastion Pattern Project)
Bastions simplify secuirty administration. The internal network can be configured to block all the internet-bound traffic. It only allows SSH communications with the bastion host. The bastion pattern grants authorized users access access to a priate network from an external network such as internet. 
1. The IAM Permissions and Roles ```roles/cloudkms.cryptoKeyEncrypterDecrypter``` is assigned
Obtains access credentials for your user account via a web-based authorization flow. When this command completes successfully, it sets the active account in the current configuration to the account specified.

## Pre-requisite for Bastion Pattern Project (Bastion Pattern Project)
1. The Principal (user or group) must enablw BigQuery API in their Google Cloud Project 
2. Have access to the GCP Project ID
3.  You will need an existing [project](https://cloud.google.com/resource-manager/docs/creating-managing-projects) with [billing enabled](https://cloud.google.com/billing/docs/how-to/modify-project) and a user with the “Project owner” [IAM](https://cloud.google.com/iam) role on that project.
4.  __Note__: to grant a user a role, take a look at the [Granting and Revoking Access](https://cloud.google.com/iam/docs/granting-changing-revoking-access#grant-single-role) documentation.
And to set the gcloud project default in your CLI
```bash
gcloud config set project <prefix>-prod-iac-core-0
```
Use the following command to access the web portal `gcloud compute ssh management-bastion --zone us-east4-a --tunnel-through-iap -- -L 8443:<ip-of-ngfw>:443`. 
From here, you should be able to access the management interface at the url https://localhost:8443/ and log in with the username `admin` and the password you found using 
in the terraform output command. *Note*: You may need to change the zone in the above command if your management bastion host wasn't deployed in `us-east4-a`.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | Project ID GCP | `string` | n/a | yes |
| location |Location of project | `string` | n/a | yes |
| allowed_source_ranges |Allowed source ranges| `string` | n/a | yes |
| my_vpc |vpc name of project | `string` | n/a | yes |
| image|Image of the bastion vm | `string` | n/a | yes |
| zone |zone of the bastion instance | `string` | n/a | yes |
| my_subnet |Name of subnet | `string` | n/a | yes |
| instance_type |Type of instance | `string` | n/a | yes |
| ip_cidr_range |This is the ip cidr range | `string` | n/a | yes |
| disk_name|Name of disk| `string` | n/a | yes |
| instance_name |Name of instance| `string` | n/a | yes |
| kms_key_self_link |Self-link of kms key| `string` | n/a | yes |
| compute_service_account_id |id of Compute Service account| `string` | n/a | yes | 
| email | Email of user | `string` | n/a | yes |
| keyring | Keyring name | `string` | n/a | yes |
| keys | Key names. | `list(string)` | `[]` | yes |
| iam | Identity and Access Management. |`list(string)` |  `[]` | yes |
| iam bindings| associates IAM policies with members | `list(string)`|  `[]` | yes |
| default|contains the duration, roation, protection, algorithm of the keys  | `list(string)` | `[]` | yes |

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

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

internal_ip = "10.0.0.2"
kms_key_self_link = "projects/my-repository/locations/us-east4/keyRings/my-keyring/cryptoKeys/default"
vpc_network = "https://www.googleapis.com/compute/v1/projects/my-repository-dev/global/networks/prod-mgmt-0"