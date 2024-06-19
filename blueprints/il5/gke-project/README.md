# Google Kubernetes Engine (GKE) Standard Project
This blueprint contains all the necessary Terraform modules to build and deploy a Google Kubernetes Engine (GKE), a managed Kubernetes cluster having encryption using the Cloud Key Management Service (KMS).   

## Introduction
- GKE is a Google-managed implementation of the Kubernetes open source container orchestration platform.  In GKE Standard mode, there is flexible node upgrade strategies to optimize availability and manage disruptions. 
- In GKE Standard mode, you pay for all resources on nodes, regardless of Pod requests. A GKE environment consists of nodes, which are Compute Engine virtual machines (VMs) with Customer-Managed Encryption Keys (CMEK) Cloud KMS that are grouped together to form a cluster. 
- This implementation offers a way to create and manage Google Kubernetes Engine (GKE) [Standard clusters](https://cloud.google.com/kubernetes-engine/docs/concepts/choose-cluster-mode#why-standard). 
- In GKE, the allocation of the nodes is done as per the Zone. For example, if there are 3 Zone and the initial node allocation per Zone is 1, then the total number of Nodes in the cluster shall be initial node allocation per zone times the total number of Zone 
- For example, If there are 3 Zone us-east4-a, us-east4-b, us-east4-c. The initial node allocation per zone is 1. Then the total number of nodes shall be 3 x 1 = 3 total nodes in the cluster.
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
Apply complete! Resources: 13 added, 0 changed, 0 destroyed.

Outputs:

gke_cluster_endpoint = "x.x.x.x"
gke_cluster_name = "cluster-name-here"
keyring-id = "projects/project-name/locations/us-east4/keyRings/keyring-name"
keyring-location = "us-east4"
keyring-name = "keyring-name"
keyring-resource = {
  "id" = "projects/project-name/locations/us-east4/keyRings/keyring-name"
  "location" = "us-east4"
  "name" = "keyring-name"
  "project" = "project-name"
  "timeouts" = null /* object */
}
keyrings-keys = {
  "keyring-version-name" = {
    "crypto_key_backend" = ""
    "destroy_scheduled_duration" = "xxxxxxs"
    "effective_labels" = tomap({
      "team" = "gke-team"
    })
    "id" = "projects/project-name/locations/us-east4/keyRings/keyring-name/cryptoKeys/keyring-version-name"
    "import_only" = false
    "key_ring" = "projects/project-name/locations/us-east4/keyRings/keyring-name"
    "labels" = tomap({
      "team" = "gke-team"
    })
    "name" = "keyring-version-name"
    "primary" = tolist([
      {
        "name" = "projects/project-name/locations/us-east4/keyRings/keyring-name/cryptoKeys/keyring-version-name/cryptoKeyVersions/1"
        "state" = "ENABLED"
      },
    ])
    "purpose" = "ENCRYPT_DECRYPT"
    "rotation_period" = "xyxyxyxs"
    "skip_initial_version_creation" = false
    "terraform_labels" = tomap({
      "team" = "update-the-team-name"
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
qualified_key_ids = {
  "keyring-version-name" = "projects/project-name/locations/us-east4/keyRings/keyring-name/cryptoKeys/keyring-version-name"
}


```
## Verification of a successful deployment?

- Go to the Google Kubernetes Engine (GKE) in the GCP Console. Select the Cluster name. 
![Google Kubernetes Engine (GKE)](./images/gke1.png?raw=true "Google Kubernetes Engine (GKE)")
- Click on the Cluster Name inside the Kubernetes Engine Panel
 
 ![Google Kubernetes Engine (GKE) Kubernetes Engine Panel](./images/gke2.png?raw=true "Google Kubernetes Engine (GKE) Kubernetes Engine Panel")