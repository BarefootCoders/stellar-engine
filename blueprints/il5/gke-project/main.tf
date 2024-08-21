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

# Work on the Current Project
data "google_project" "current" {}


# Custom service account with compute engine role  
resource "google_service_account" "gke" {
  account_id = var.gke_service_account_id
  project    = var.project_id
}


# #Create KMS Key Ring and Crypto Key using the kms module
module "kms" {
  source     = "../../../modules/kms"
  project_id = var.project_id
  keys       = var.keys
  keyring    = var.keyring
  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
      "user:${var.email}",
      "group:${var.group_email}",
      google_service_account.gke.member,
      "serviceAccount:service-${data.google_project.current.number}@compute-system.iam.gserviceaccount.com",
    ]
  }
}


# Google VPC Module management of VPC networks including subnetworks
module "vpc" {
  source                  = "../../../modules/net-vpc"
  project_id              = var.project_id
  name                    = var.vpc_name
  auto_create_subnetworks = false
  subnets = [
    {
      ip_cidr_range = var.subnet_ip_cidr_range_1
      name          = var.subnet_name
      region        = var.region
      secondary_ip_ranges = {
        pods     = var.subnet_secondary_ip_range_pods_1
        services = var.subnet_secondary_ip_range_services_1
      }
    }
  ]
  depends_on = [module.kms]
}


# Google GKE Kubernetes Standard Module
module "cluster" {
  source              = "../../../modules/gke-cluster-standard"
  project_id          = var.project_id
  name                = var.gke_cluster_name
  location            = var.region
  deletion_protection = false
  vpc_config = {
    master_ipv4_cidr_block = var.gke_vpc_master_ipv4_cidr_block
    network                = module.vpc.self_link
    subnetwork             = module.vpc.subnet_self_links["${var.region}/${var.subnet_name}"]
    master_authorized_ranges = {
      internal-vms = var.master_authorized_ranges_ip_ranges
    }
  }
  default_nodepool = {
    initial_node_count       = var.gke_initial_node_per_zone
    remove_pool              = false
    remove_default_node_pool = false
  }
  node_config = {
    boot_disk_kms_key = module.kms.keys.default.id
    service_account   = google_service_account.gke.email
    tags              = var.node_config_tags
  }
  enable_features = {
    enable_shielded_nodes = true
    dataplane_v2          = true
    binary_authorization  = true
  }

  private_cluster_config = {
    enable_private_endpoint = var.gke_cluster_enable_private_endpoint
    master_global_access    = var.gke_cluster_master_global_access
  }
  depends_on = [module.vpc, module.kms]
}


# Google GKE Kubernetes NodePool Module
module "cluster_nodepool" {
  source       = "../../../modules/gke-nodepool"
  project_id   = var.project_id
  cluster_name = var.gke_cluster_name
  location     = var.region
  name         = var.gke_nodepool_name
  node_count   = var.nodepool_node_count
  service_account = {
    create = false
  }
  node_config = {
    boot_disk_kms_key = module.kms.keys.default.id
    disk_size_gb      = var.node_disk_size_gb
    machine_type      = var.node_machine_type
    service_account   = "serviceAccount:${google_service_account.gke.email}"
    shielded_instance_config = {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
  depends_on = [module.vpc, module.cluster, module.kms]
}
