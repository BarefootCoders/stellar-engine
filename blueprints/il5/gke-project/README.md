# Google Kubernetes Engine (GKE) Standard Project
This blueprint contains all the necessary Terraform modules to build and deploy a Google Kubernetes Engine (GKE), a managed Kubernetes cluster having encryption using the Cloud Key Management Service (KMS).   

## Introduction
- GKE is a Google-managed implementation of the Kubernetes open source container orchestration platform.  In GKE Standard mode, there are flexible node upgrade strategies to optimize availability and manage disruptions. 
- In GKE Standard mode, you pay for all resources on nodes, regardless of Pod requests. A GKE environment consists of nodes, which are Compute Engine virtual machines (VMs) with Customer-Managed Encryption Keys (CMEK) Cloud KMS that are grouped together to form a cluster. 
- This implementation offers a way to create and manage Google Kubernetes Engine (GKE) [Standard clusters](https://cloud.google.com/kubernetes-engine/docs/concepts/choose-cluster-mode#why-standard). 
- In GKE, the allocation of the nodes is done as per the Zone. For more details refer to the GKE cluster configuration choices  [GKE cluster configuration choices](https://cloud.google.com/kubernetes-engine/docs/concepts/types-of-clusters)
- For example, If there are 3 Zone gcp-region-name-a, gcp-region-name-b, gcp-region-name-c. The initial node allocation per zone is 1. Then the total number of nodes shall be 3 x 1 = 3 total nodes in the cluster.
## Pre-requisite
1. The Principal (user or group) must have Cloud KMS Admin, Able to Deploy a Google VPC, GKE Create, permission at the GCP Level.
2. Have access to the GCP Project ID
3.  You will need an existing [project](https://cloud.google.com/resource-manager/docs/creating-managing-projects) with [billing enabled](https://cloud.google.com/billing/docs/how-to/modify-project) and a user with the “Project owner” [IAM](https://cloud.google.com/iam) role on that project. __Note__: to grant a user a role, take a look at the [Granting and Revoking Access](https://cloud.google.com/iam/docs/granting-changing-revoking-access#grant-single-role) documentation.


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

The Output will look like following
```
Apply complete! Resources: 11 added, 0 changed, 0 destroyed.

Outputs:

cluster_master_version = "1.29.4-gke.1043002"
gke_cluster_endpoint = "x.x.x.x"
gke_cluster_name = "gke_cluster_name_xxx"
keyring_id = "projects/project-name-xxx/locations/us-xxxxx/keyRings/keyring-xxx"
keyring_location = "us-xxxxx"
keyring_name = "keyring-xxx"
keyring_resource = {
  "id" = "projects/project-name-xxx/locations/us-xxxxx/keyRings/keyring-xxx"
  "location" = "us-xxxxx"
  "name" = "keyring-xxx"
  "project" = "project-name-xxx"
  "timeouts" = null /* object */
}
keyrings_keys = {
  "keys-xxx" = {
    "crypto_key_backend" = ""
    "destroy_scheduled_duration" = "2592000s"
    "effective_labels" = tomap({
      "team" = "xxxx-team"
    })
    "id" = "projects/project-name-xxx/locations/us-xxxxx/keyRings/keyring-xxx/cryptoKeys/keys-xxx"
    "import_only" = false
    "key_ring" = "projects/project-name-xxx/locations/us-xxxxx/keyRings/keyring-xxx"
    "labels" = tomap({
      "team" = "team-xxx"
    })
    "name" = "keys-xxx"
    "primary" = tolist([
      {
        "name" = "projects/project-name-xxx/locations/us-xxxxx/keyRings/keyring-xxx/cryptoKeys/keys-xxx/cryptoKeyVersions/1"
        "state" = "ENABLED"
      },
    ])
    "purpose" = "ENCRYPT_DECRYPT"
    "rotation_period" = "7776000s"
    "skip_initial_version_creation" = false
    "terraform_labels" = tomap({
      "team" = "team-xxx"
    })
    "timeouts" = null /* object */
    "version_template" = tolist([
      {
        "algorithm" = "GOOGLE_SYMMETRIC_ENCRYPTION"
        "protection_level" = "SOFTWARE"
      },
    ])
  }
}
nodepool_id = "projects/project-name-xxx/locations/us-xxxxx/clusters/gke_cluster_name_xxx/nodePools/gke-nodepoolkc"
nodepool_name = "gke-nodepoolkc"
subnet_regions = {
  "us-xxxxx/subnet-name-xxx" = "us-xxxxx"
}
subnets = {
  "us-xxxxx/subnet-name-xxx" = {
    "description" = "Terraform-managed."
    "fingerprint" = tostring(null)
    "gateway_address" = "x.x.x.x"
    "id" = "projects/project-name-xxx/regions/us-xxxxx/subnetworks/subnet-name-xxx"
    "internal_ipv6_prefix" = ""
    "ip_cidr_range" = "x.x.x.x/22"
    "ipv6_access_type" = ""
    "ipv6_cidr_range" = ""
    "log_config" = tolist([])
    "name" = "subnet-name-xxx"
    "network" = "https://www.googleapis.com/compute/v1/projects/project-name-xxx/global/networks/vpc-name-xxx"
    "private_ip_google_access" = true
    "private_ipv6_google_access" = "DISABLE_GOOGLE_ACCESS"
    "project" = "project-name-xxx"
    "purpose" = "PRIVATE"
    "region" = "us-xxxxx"
    "role" = ""
    "secondary_ip_range" = tolist([
      {
        "ip_cidr_range" = "x.x.x.x/14"
        "range_name" = "pods"
      },
      {
        "ip_cidr_range" = "x.x.x.x/20"
        "range_name" = "services"
      },
    ])
    "self_link" = "https://www.googleapis.com/compute/v1/projects/project-name-xxx/regions/us-xxxxx/subnetworks/subnet-name-xxx"
    "stack_type" = "IPV4_ONLY"
    "timeouts" = null /* object */
  }
}
vpc-network = {
  "id" = "projects/project-name-xxx/global/networks/vpc-name-xxx"
  "name" = "vpc-name-xxx"
  "self_link" = "https://www.googleapis.com/compute/v1/projects/project-name-xxx/global/networks/vpc-name-xxx"
}
vpc-subnet_ids = {
  "us-xxxxx/subnet-name-xxx" = "projects/project-name-xxx/regions/us-xxxxx/subnetworks/subnet-name-xxx"
}
vpc-subnet_ips = {
  "us-xxxxx/subnet-name-xxx" = "x.x.x.x/22"
}


```
## Verification of a successful deployment?

- Go to the Google Kubernetes Engine (GKE) in the GCP Console. Select the Cluster name. 
![Google Kubernetes Engine (GKE)](./images/gke1.png?raw=true "Google Kubernetes Engine (GKE)")
- Click on the Cluster Name inside the Kubernetes Engine Panel
 
 ![Google Kubernetes Engine (GKE) Kubernetes Engine Panel](./images/gke2.png?raw=true "Google Kubernetes Engine (GKE) Kubernetes Engine Panel")


## Cleanup
Once the project is deployed, to ensure clean up, please apply following command.
```bash
terraform destory
```
