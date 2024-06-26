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
