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
resource "google_project_service_identity" "gcp_sa_cloud_sql" {
  project  = var.project_id
  provider = google-beta
  service  = "sqladmin.googleapis.com"
}
resource "google_sql_database_instance" "postgres" {
  name                = var.database_name
  database_version    = var.database_version
  region              = var.region
  encryption_key_name = google_kms_crypto_key.crypto_key1.id
  deletion_protection = false
  project             = var.project_id

  settings {
    tier = var.database_instance_tier

    ip_configuration {
      ipv4_enabled    = true
      private_network = data.google_compute_network.vpc_network.self_link
      require_ssl     = true
    }
  }
}

resource "google_kms_key_ring" "key-ring01" {
  name     = "cloud-sql-key-ring0"
  location = var.region
  project  = var.project_id
}

resource "google_kms_crypto_key" "crypto_key1" {
  name            = "cloud-sql-encryption-key"
  key_ring        = google_kms_key_ring.key-ring01.id
  rotation_period = "7776000s"
  purpose         = "ENCRYPT_DECRYPT"
}

resource "google_kms_crypto_key_iam_binding" "crypto_key" {
  crypto_key_id = google_kms_crypto_key.crypto_key1.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:${google_project_service_identity.gcp_sa_cloud_sql.email}",
  ]
}

data "google_compute_network" "vpc_network" {
  name    = var.network_name
  project = var.project_id
}
