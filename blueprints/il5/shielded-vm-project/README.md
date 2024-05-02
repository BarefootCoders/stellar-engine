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
4.__Important Note__: The project is scoped around the computer engine shielded VM, and in order to deploy the code, there is a dependency on the Google VPC module (VPC and subnet), and the code uses the Google VPC module along with the Google KMS module. As per requirements, The CFF stages are supposed to set that up for new projects. 


## Pre-requisite
1. The Principal (user or group) must have Cloud KMS Admin permission at the GCP Level.
2. Have access to the GCP Project ID
3.  You will need an existing [project](https://cloud.google.com/resource-manager/docs/creating-managing-projects) with [billing enabled](https://cloud.google.com/billing/docs/how-to/modify-project) and a user with the “Project owner” [IAM](https://cloud.google.com/iam) role on that project. __Note__: to grant a user a role, take a look at the [Granting and Revoking Access](https://cloud.google.com/iam/docs/granting-changing-revoking-access#grant-single-role) documentation.


## How to deploy the Terraform Code. The Deployment Steps
You should see this README and some terraform files.
1. Update the Variables in the variables.tf , that are marked as "# TODO: Update"
2. There is a sample ```terraform.tfvars.sample``` available as wellthat 
3. Although each use case is somehow built around the previous one they are self-contained so you can deploy any of them at your will. The usual terraform commands will do the work:

```bash
terraform init
terraform plan
terraform apply
```

It will take a few minutes. When complete, you should see an output stating the command completed successfully, a list of the created resources.

The Output will look like following
```

Outputs:

keyring-id = "projects/project-name/locations/us-east4/keyRings/name-keyring"
keyring-location = "us-east4"
keyring-name = "name-keyring"
keyring-resource = {
  "id" = "projects/project-name/locations/us-east4/keyRings/name-keyring"
  "location" = "us-east4"
  "name" = "name-keyring"
  "project" = "project-name"
  "timeouts" = null /* object */
}
keyrings-keys = {
  "default" = {
    "crypto_key_backend" = ""
    "destroy_scheduled_duration" = "2592000s"
    "effective_labels" = tomap({})
    "id" = "projects/project-name/locations/us-east4/keyRings/name-keyring/cryptoKeys/default"
    "import_only" = false
    "key_ring" = "projects/project-name/locations/us-east4/keyRings/name-keyring"
    "labels" = tomap(null) /* of string */
    "name" = "default"
    "primary" = tolist([
      {
        "name" = "projects/project-name/locations/us-east4/keyRings/name-keyring/cryptoKeys/default/cryptoKeyVersions/1"
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
        "protection_level" = "SOFTWARE"
      },
    ])
  }
}
shielded-vm-instance = <sensitive>
shielded-vm-instance-id = "projects/project-name/zones/us-east4-c/instances/instance-name"
shielded-vm-internal_ip = "10.0.1.2"
shielded-vm-internal_ips = [
  "10.0.1.2",
]
shielded-vm-service_account_email = "Email-address-sample-@project-name.iam.gserviceaccount.com"
```

## Verification of a successful deployment?

- Go to the Compute Engine in the GCP Console.
![GCP Compute Engine Instance](./images/vm-1.png?raw=true "GCP Compute Engine Instance")

- Try to SSH and you will be able to SSH with proper permission
![GCP Compute Engine SSH](./images/vm-2.png?raw=true "GCP Compute Engine SSH")
