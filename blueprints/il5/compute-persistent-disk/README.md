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
