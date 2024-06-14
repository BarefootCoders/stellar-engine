/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
# Terraform Provider for Google Cloud Platform
provider "google" {
  project = var.project_id
  region  = var.region
}


# Work on the Current Project
data "google_project" "current" {}


# Custom service account with compute engine role  
resource "google_service_account" "compute" {
  account_id = var.compute_service_account_id
  project    = var.project_id
}


#Create KMS Key Ring and Crypto Key using the kms module
# module "kms" {
#   source     = "../../../modules/kms"
#   project_id = var.project_id
#   keys       = var.keys
#   keyring    = var.keyring
#   iam = {
#     "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
#       "user:${var.email}",
#       "group:${var.group_email}",
#       "serviceAccount:${google_service_account.compute.email}",
#       "serviceAccount:service-${data.google_project.current.number}@compute-system.iam.gserviceaccount.com",
#     ]
#   }
# }

# Google VPC Module
module "vpc" {
  source                  = "../../../modules/net-vpc"
  project_id              = var.project_id
  name                    = "vpc-gke-kube"
  auto_create_subnetworks = false
  subnets = [
    {
      ip_cidr_range = "10.0.4.0/22"
      name          = "subnet-kube-1"
      region        = var.region
      secondary_ip_ranges = {
        pods     = "10.4.0.0/14"
        services = "10.0.32.0/20"
      }
    }

  ]
}

# Google Cloud NAT Module
module "nat" {
  source         = "../../../modules/net-cloudnat"
  project_id     = var.project_id
  region         = var.region
  name           = "dev-kube-nat"
  router_network = module.vpc.name
  depends_on     = [module.vpc]
}

# Google GKE Kubernetes Standard Module
module "cluster" {
  source              = "../../../modules/gke-cluster-standard"
  project_id          = var.project_id
  name                = "cluster-kube-2"
  location            = var.region
  deletion_protection = false


  vpc_config = {
    master_ipv4_cidr_block = "192.168.0.0/28"
    network                = module.vpc.self_link
    subnetwork             = module.vpc.subnet_self_links["${var.region}/subnet-kube-1"]
  }
  node_config = {
    boot_disk_kms_key        = "projects/${var.project_id}/locations/${var.region}/keyRings/${var.keyring.name}/cryptoKeys/gke-keynamev2"
    deletion_protection      = false
    remove_default_node_pool = false
    initial_node_count       = 3

  }
  private_cluster_config = {
    enable_private_endpoint = false
    master_global_access    = false
  }


  depends_on = [module.vpc]
}

resource "google_kms_crypto_key_iam_binding" "gke_key_encrypter_decrypter" {
  crypto_key_id = "projects/${var.project_id}/locations/${var.region}/keyRings/${var.keyring.name}/cryptoKeys/gke-keynamev2"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members = [
    "user:${var.email}",
    "group:${var.group_email}",
    "serviceAccount:${google_service_account.compute.email}",
    "serviceAccount:service-${data.google_project.current.number}@compute-system.iam.gserviceaccount.com",
  ]
  depends_on = [module.vpc]
}

# Google GKE Kubernetes NodePool Module
module "cluster_nodepool" {
  source       = "../../../modules/gke-nodepool"
  project_id   = var.project_id
  cluster_name = "cluster-kube-2"
  location     = var.region
  name         = "nodepool-kube-1"
  service_account = {
    create = false
  }
  node_config = {
    boot_disk_kms_key = "projects/${var.project_id}/locations/${var.region}/keyRings/${var.keyring.name}/cryptoKeys/gke-keynamev2"
    disk_size_gb      = 20
    machine_type      = "e2-medium"
  }
  node_count = { initial = 2 }
  depends_on = [module.vpc, module.cluster]
}


