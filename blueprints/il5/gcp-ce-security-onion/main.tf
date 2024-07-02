/**
 * Copyright 2024 Google LLC
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
  region  = var.location
}

# Work on the Current Project
data "google_project" "current" {}

# Custom service account with compute engine role  
resource "google_service_account" "compute" {
  account_id = var.compute_service_account_id
  project    = var.project_id
}

# Google KMS Module
module "kms" {
  source     = "../../../modules/kms"
  project_id = var.project_id
  keys       = var.keys
  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
      google_service_account.compute.member,
      "serviceAccount:service-${data.google_project.current.number}@compute-system.iam.gserviceaccount.com",
      "user:${var.email}"
    ]
  }
  keyring = var.keyring
}

# Using the Google Compute Engine VM Module for Security Onion
module "compute-engine-vm" {
  source        = "../../../modules/compute-vm"
  project_id    = var.project_id
  zone          = var.zone
  name          = var.instance_name
  instance_type = var.instance_type
  boot_disk = {
    initialize_params = {
      size  = var.boot_disk_size_gb
      image = var.boot_disk_image
      type  = "pd-ssd"
    }
  }
  network_interfaces = [
    {
      network    = module.vpc-a.network.self_link
      subnetwork = "projects/${var.project_id}/regions/${var.location}/subnetworks/${var.subnet_a_name}"
    },
    {
      network    = module.vpc-b.network.self_link
      subnetwork = "projects/${var.project_id}/regions/${var.location}/subnetworks/${var.subnet_b_name}"
    }
  ]
  # Define metadata, including the startup script
  metadata = {
    startup-script = file("${path.module}/startup-script.sh")
  }
  tags = ["security-onion"]
  encryption = {
    kms_key_self_link = module.kms.keys.default.id
  }
  service_account = {
    email = google_service_account.compute.email
  }
  # Persistent Disk Attached to the Compute Engine
  attached_disks = [
    {
      auto_delete = var.auto_delete
      size        = var.boot_disk_size_gb
      name        = "data-disk"
      initialize_params = {
        image = var.boot_disk_image
      }
    }
  ]
  depends_on = [google_service_account.compute, module.vpc-a, module.vpc-b, module.nat-a, module.nat-b, google_compute_firewall.defaulta, google_compute_firewall.defaultb, module.kms]
}

# Google VPC Module - First VPC
module "vpc-a" {
  source                  = "../../../modules/net-vpc"
  project_id              = var.project_id
  name                    = var.vpc_a_name
  auto_create_subnetworks = false
  subnets = [
    {
      ip_cidr_range = var.subnet_a_ip_cidr
      name          = var.subnet_a_name
      region        = var.location
      secondary_ip_ranges = {
        pods     = var.subnet_a_secondary_ip_cidr_1
        services = var.subnet_a_secondary_ip_cidr_2
      }
    }
  ]
}

# Google VPC Module - Second VPC
module "vpc-b" {
  source                  = "../../../modules/net-vpc"
  project_id              = var.project_id
  name                    = var.vpc_b_name
  auto_create_subnetworks = false
  subnets = [
    {
      ip_cidr_range = var.subnet_b_ip_cidr
      name          = var.subnet_b_name
      region        = var.location
      secondary_ip_ranges = {
        pods     = var.subnet_b_secondary_ip_cidr_1
        services = var.subnet_b_secondary_ip_cidr_2
      }
    }
  ]
}

# Google Cloud NAT Module - Simple Cloud NAT management for VPC A
module "nat-a" {
  source         = "../../../modules/net-cloudnat"
  project_id     = var.project_id
  region         = var.location
  name           = var.nat_a_name
  router_network = module.vpc-a.name
  depends_on     = [module.vpc-a]
}

# Google Cloud NAT Module - Simple Cloud NAT management for VPC B
module "nat-b" {
  source         = "../../../modules/net-cloudnat"
  project_id     = var.project_id
  region         = var.location
  name           = var.nat_b_name
  router_network = module.vpc-b.name
  depends_on     = [module.vpc-b]
}

# Google Compute Firewall with rules
resource "google_compute_firewall" "defaulta" {
  name    = "allow-traffic-a"
  network = module.vpc-a.network.self_link
  allow {
    protocol = "all"
  }
  # Allowing to connect only within the VPC CIDR Range
  source_ranges = var.source_ranges_cidrs
  target_tags   = []
}

# Google Compute Firewall with rules
resource "google_compute_firewall" "defaultb" {
  name    = "allow-traffic-b"
  network = module.vpc-b.network.self_link
  allow {
    protocol = "all"
  }
  # Allowing to connect only within the VPC CIDR Range
  source_ranges = var.source_ranges_cidrs
  target_tags   = []
}

# Google Compute Firewall with rules
resource "google_compute_firewall" "egressa" {
  name      = "allow-egress-a"
  network   = module.vpc-a.network.self_link
  direction = "EGRESS"
  allow {
    protocol = "all"
  }
  # Allowing to connect only within the VPC CIDR Range
  source_ranges = var.source_ranges_cidrs
  target_tags   = []
}

# Google Compute Firewall with rules
resource "google_compute_firewall" "egressb" {
  name      = "allow-egress-b"
  network   = module.vpc-b.network.self_link
  direction = "EGRESS"
  allow {
    protocol = "all"
  }
  # Allowing to connect only within the VPC CIDR Range
  source_ranges = var.source_ranges_cidrs
  target_tags   = []
}