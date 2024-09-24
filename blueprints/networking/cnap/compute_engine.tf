/**
 * Copyright 2022 Google LLC
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

locals {
  nva_zones = ["b", "c"]
}

# Custom service account with compute engine role
resource "google_service_account" "compute" {
  account_id = "cnap-compute-sa"
  project    = data.google_project.project.project_id
}

data "google_compute_default_service_account" "default" {
  project = data.google_project.project.project_id
}

data "google_compute_subnetwork" "default" {
  name    = var.subnet
  project = var.net_project
}

# Demo App config
module "cos-demo-config" {
  source          = "../../../modules/cloud-config-container/cos-generic-metadata"
  for_each        = local.vms
  container_image = each.value.container_image
  container_name  = "demo"

}

module "cos-template" {
  for_each        = local.vms
  source          = "../../../modules/compute-vm"
  project_id      = data.google_project.project.project_id
  name            = "cos-template-${each.key}"
  zone            = "${var.region}-b"
  instance_type   = "n2d-standard-2"
  tags            = ["${var.prefix}-ids"]
  create_template = true
  network_interfaces = [
    {
      network    = data.google_compute_network.landing-vpc.id
      subnetwork = data.google_compute_subnetwork.default.self_link
      nat        = false
    }
  ]
  boot_disk = {
    initialize_params = {
      image = "cos-cloud/cos-stable"
    }
  }
  options = {
    allow_stopping_for_update = true
    deletion_protection       = false
    spot                      = true
    termination_action        = "STOP"
  }
  metadata = {
    user-data = module.cos-demo-config[each.key].cloud_config
  }
  # CIS Compliance Benchmark 4.1/4.2
  service_account = {
    email = google_service_account.compute.email
  }

  # CIS Compliance Benchmark 4.11
  confidential_compute = true
  shielded_config = {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
}

module "cos-mig" {
  for_each          = local.vms
  source            = "../../../modules/compute-mig"
  project_id        = data.google_project.project.project_id
  location          = var.region
  name              = "cos-${each.key}"
  instance_template = module.cos-template[each.key].template.self_link
  target_size       = 1
  auto_healing_policies = {
    initial_delay_sec = 30
  }
  health_check_config = {
    enable_logging = true
    tcp = {
      port = 22
    }
  }
  named_ports = {
    http = 80
  }
}

# Google KMS Module
module "kms" {
  source     = "../../../modules/kms"
  project_id = data.google_project.project.project_id
  keys = {
    "default" = {
      purpose = "ENCRYPT_DECRYPT"
      version_template = {
        algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
        protection_level = "HSM"
      }
    }
  }

  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
      google_service_account.compute.member,
      data.google_compute_default_service_account.default.member
    ]
  }
  keyring = {
    location = var.region
    name     = "cnap-keyring"
  }

}
