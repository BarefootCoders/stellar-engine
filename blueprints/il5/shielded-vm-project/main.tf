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


# Work on the Current Project
data "google_project" "current" {}

# Custom service account with compute engine role  
resource "google_service_account" "compute" {
  account_id = var.compute_service_account_id
  project    = var.project_id
}

# Google Compute Shielded VM Module
module "shielded-vm" {
  source     = "../../../modules/compute-vm"
  project_id = var.project_id
  zone       = var.zone
  name       = var.instance_name
  shielded_config = {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  metadata = {
    block-project-ssh-keys = true # CIS Compliance Benchmark 4.3
    # enable-oslogin         = "TRUE" # CIS Compliance Benchmark 4.4 - Uncomment if no org policy
    # enable-osconfig = "TRUE" # CIS Compliance Benchmark 4.12 - Uncomment if no org policy
  }

  instance_type        = var.instance_type
  confidential_compute = true # CIS Compliance Benchmark 4.11 - Must use compliant instance type

  network_interfaces = [{
    network    = module.vpc.network.self_link
    subnetwork = module.vpc.subnet_self_links["${var.location}/${var.subnet_name}"]
  }]
  encryption = {
    kms_key_self_link = module.kms.keys.default.id
  }

  # CIS Compliance Benchmark 4.1/4.2
  service_account = {
    email = google_service_account.compute.email
  }
  attached_disks = [
    {
      auto_delete       = true
      size              = var.disksize
      name              = "data-disk"
      kms_key_self_link = module.kms.keys.default.id
    }
  ]

  boot_disk = {
    initialize_params = {
      image = "cos-cloud/cos-stable" #Required for Confidential Compute
    }
  }

  depends_on = [module.kms, google_service_account.compute]
}

# Google KMS Module
module "kms" {
  source     = "../../../modules/kms"
  project_id = var.project_id
  keys       = var.keys
  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
      google_service_account.compute.member,
      "serviceAccount:service-${data.google_project.current.number}@compute-system.iam.gserviceaccount.com"
    ]
  }
  keyring = var.keyring
}

# Google VPC Module
module "vpc" {
  source                          = "../../../modules/net-vpc"
  project_id                      = var.project_id
  name                            = var.vpc_name
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
  routing_mode                    = "GLOBAL"
  subnets = [
    {
      name          = var.subnet_name
      region        = var.location
      ip_cidr_range = var.ip_cidr_range
    }
  ]
}
# Google Computer Firewall
resource "google_compute_firewall" "default" {
  name    = "allow-firewall-rules"
  network = module.vpc.network.self_link
  allow {
    protocol = "tcp"
    ports    = var.allowed_firewall_ports
  }
  # Allowing to connect only within the VPC CIDR Range
  source_ranges = var.source_ranges_allowed
}