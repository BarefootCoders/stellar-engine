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

data "google_project" "landing_project" {
  project_id = var.landing_project_id
}

data "google_project" "core_project" {
  project_id = var.iac_project_id
}

data "google_compute_network" "network" {
  name    = var.network_name
  project = var.landing_project_id
}

# Dataproc Customer Service Account
resource "google_service_account" "dataproc_vm" {
  account_id   = var.project_id
  display_name = "Dataproc Worker Service Account"
}

#  https://cloud.google.com/dataproc/docs/concepts/configuring-clusters/network
resource "google_compute_firewall" "dataproc" {
  project = var.landing_project_id
  name    = var.firewall_name
  network = data.google_compute_network.network.self_link
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = ["10.128.0.0/9"]
}

module "gcs" {
  source         = "../../../modules/gcs"
  prefix         = "tmp"
  project_id     = var.project_id
  location       = var.region
  storage_class  = "STANDARD"
  encryption_key = "projects/${var.iac_project_id}/locations/${var.region}/keyRings/${var.keyring}/cryptoKeys/${var.key}"
  name           = var.dataproc_bucket_name

  iam = {
    "roles/storage.objectViewer" = concat(
      [
        google_service_account.dataproc_vm.member
      ]
    )
    "roles/storage.objectCreator" = concat(
      [
        google_service_account.dataproc_vm.member
      ]
    )
  }

  force_destroy = true

  depends_on = [google_kms_crypto_key_iam_binding.dataproc_kms]
}

module "dataproc_cluster" {
  source     = "../../../modules/dataproc"
  project_id = var.project_id
  name       = var.cluster_name
  region     = var.region
  dataproc_config = {
    cluster_config = {

      # Encryption on the Cluster does not work as of 14 NOV 2024
      encryption_config = {
        kms_key_name = "projects/${var.iac_project_id}/locations/${var.region}/keyRings/${var.keyring}/cryptoKeys/${var.key}"
      }

      staging_bucket = module.gcs.name
      temp_bucket    = module.gcs.name
      gce_cluster_config = {
        internal_ip_only       = true
        service_account        = google_service_account.dataproc_vm.email
        service_account_scopes = ["cloud-platform"]
        subnetwork             = "projects/${var.landing_project_id}/regions/${var.region}/subnetworks/${var.subnet_name}"
        tags                   = ["dataproc"]
        zone                   = "${var.region}-c"
      }
    }
  }

  depends_on = [
    google_kms_crypto_key_iam_binding.dataproc_kms
  ]

}

