# Google Kubernetes Engine (GKE) Standard Project
This blueprint contains all the necessary Terraform modules to build and deploy a Google Kubernetes Engine (GKE), a managed Kubernetes cluster having encryption using the Cloud Key Management Service (KMS).   

## Introduction
- GKE is a Google-managed implementation of the Kubernetes open source container orchestration platform.  In GKE Standard mode, there is flexible node upgrade strategies to optimize availability and manage disruptions. 
- In GKE Standard mode, you pay for all resources on nodes, regardless of Pod requests. A GKE environment consists of nodes, which are Compute Engine virtual machines (VMs) with Customer-Managed Encryption Keys (CMEK) Cloud KMS that are grouped together to form a cluster. 
- This implementation offers a way to create and manage Google Kubernetes Engine (GKE) [Standard clusters](https://cloud.google.com/kubernetes-engine/docs/concepts/choose-cluster-mode#why-standard). 
- In GKE, the allocation of the nodes is done as per the Zone. For example, if there are 3 Zone and the initial node allocation per Zone is 1, then the total number of Nodes in the cluster shall be initial node allocation per zone times the total number of Zone 
- For example, If there are 3 Zone gcp-region-name-a, gcp-region-name-b, gcp-region-name-c. The initial node allocation per zone is 1. Then the total number of nodes shall be 3 x 1 = 3 total nodes in the cluster.
## Pre-requisite
1. The Principal (user or group) must have Cloud KMS Admin, Able to Deploy a Google VPC, GKE Create, permission at the GCP Level.
2. Have access to the GCP Project ID
3.  You will need an existing [project](https://cloud.google.com/resource-manager/docs/creating-managing-projects) with [billing enabled](https://cloud.google.com/billing/docs/how-to/modify-project) and a user with the “Project owner” [IAM](https://cloud.google.com/iam) role on that project. __Note__: to grant a user a role, take a look at the [Granting and Revoking Access](https://cloud.google.com/iam/docs/granting-changing-revoking-access#grant-single-role) documentation.


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
Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

Outputs:

gke_cluster_endpoint = "x.x.x.x"
gke_cluster_name = "gke-cluster-name"
nodepool_id = "projects/project-name/locations/gcp-region-name/clusters/gke-cluster-name/nodePools/nodepool-name-here"
nodepool_name = "nodepool-name-here"
subnet_regions = {
  "gcp-region-name/subnet-xxx-xxx" = "gcp-region-name"
}
subnets = {
  "gcp-region-name/subnet-xxx-xxx" = {
    "description" = "Terraform-managed."
    "external_ipv6_prefix" = ""
    "fingerprint" = tostring(null)
    "gateway_address" = "x.x.x.x"
    "id" = "projects/project-name/regions/gcp-region-name/subnetworks/subnet-xxx-xxx"
    "internal_ipv6_prefix" = ""
    "ip_cidr_range" = "x.x.x.x/22"
    "ipv6_access_type" = ""
    "ipv6_cidr_range" = ""
    "log_config" = tolist([])
    "name" = "subnet-xxx-xxx"
    "network" = "https://www.googleapis.com/compute/v1/projects/project-name/global/networks/vpc-name-here"
    "private_ip_google_access" = true
    "project" = "project-name"
    "purpose" = "PRIVATE"
    "region" = "gcp-region-name"
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
    "self_link" = "https://www.googleapis.com/compute/v1/projects/project-name/regions/gcp-region-name/subnetworks/subnet-xxx-xxx"
    "stack_type" = "IPV4_ONLY"
    "timeouts" = null /* object */
  }
}
vpc-network = {
  "id" = "projects/project-name/global/networks/vpc-name-here"
  "name" = "vpc-name-here"
  "self_link" = "https://www.googleapis.com/compute/v1/projects/project-name/global/networks/vpc-name-here"
}
vpc-subnet_ids = {
  "gcp-region-name/subnet-xxx-xxx" = "projects/project-name/regions/gcp-region-name/subnetworks/subnet-xxx-xxx"
}
vpc-subnet_ips = {
  "gcp-region-name/subnet-xxx-xxx" = "x.x.x.x/22"
}


```
## Verification of a successful deployment?

- Go to the Google Kubernetes Engine (GKE) in the GCP Console. Select the Cluster name. 
![Google Kubernetes Engine (GKE)](./images/gke1.png?raw=true "Google Kubernetes Engine (GKE)")
- Click on the Cluster Name inside the Kubernetes Engine Panel
 
 ![Google Kubernetes Engine (GKE) Kubernetes Engine Panel](./images/gke2.png?raw=true "Google Kubernetes Engine (GKE) Kubernetes Engine Panel")