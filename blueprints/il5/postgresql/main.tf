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

data "google_project" "current" {}

data "google_compute_network" "network" {
  name = var.network_name
}

resource "google_compute_global_address" "postgres" {
  name          = var.google_compute_global_address_name
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = data.google_compute_network.network.self_link
}

resource "google_service_networking_connection" "postgres" {
  network                 = data.google_compute_network.network.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.postgres.name]
}

resource "google_compute_firewall" "postgres" {
  name    = var.firewall_name
  network = data.google_compute_network.network.self_link
  allow {
    protocol = "tcp"
    ports    = var.allowed_firewall_ports
  }
  source_ranges = var.firewall_source_range
}

module "kms" {
  source     = "../../../modules/kms"
  project_id = var.project_id
  keys       = var.keys

  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = concat(
      [
        "serviceAccount:service-${data.google_project.current.number}@service-networking.iam.gserviceaccount.com",
        "serviceAccount:service-${data.google_project.current.number}@gcp-sa-cloud-sql.iam.gserviceaccount.com"
      ]
    )
  }

  keyring = var.keyring

  depends_on = [google_service_networking_connection.postgres]
}

module "postgres" {
  source     = "../../../modules/cloudsql-instance"
  project_id = var.project_id
  network_config = {
    connectivity = {
      psa_config = {
        private_network = data.google_compute_network.network.self_link
      }
    }
  }
  name             = var.database_name
  region           = var.region
  database_version = var.database_version
  tier             = var.database_instance_tier

  encryption_key_name = module.kms.keys.postgres.id

  # Required for IL5 - location must be set
  backup_configuration = {
    enabled  = true
    location = var.region
  }

  terraform_deletion_protection = var.deletion_protection
  gcp_deletion_protection       = var.deletion_protection

  depends_on = [module.kms, resource.google_service_networking_connection.postgres]

  # CIS Compliance Benchmark 6.2
  flags = {
    log_error_verbosity        = var.log_error_verbosity
    log_connections            = var.log_connections
    log_disconnections         = var.log_disconnections
    log_statement              = var.log_statement
    log_min_messages           = var.log_min_messages
    log_min_error_statement    = var.log_min_error_statement
    log_min_duration_statement = var.log_min_duration_statement
    "cloudsql.enable_pgaudit"  = var.enable_pgaudit
  }
}
