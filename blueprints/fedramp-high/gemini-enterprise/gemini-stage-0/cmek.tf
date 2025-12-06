# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

locals {
  kms_rotation_period = "7776000s" # 90 days
  # Use provided key or the newly created resource key
  # If geolocation is "us" and we created a US key, use that.
  cmek_key_id = (var.geolocation == "us" && length(google_kms_crypto_key.us_crypto_key) > 0) ? google_kms_crypto_key.us_crypto_key[0].id : (var.create_resource_keys ? google_kms_crypto_key.resources[0].id : var.kms_key_id)
}

# ---------------------------------------------------------------------------- #
# CMEK Key Ring
# ---------------------------------------------------------------------------- #
# Data source to read the keyring from the provided KMS Key ID (State Key)
data "google_kms_key_ring" "cmek_key_ring" {
  name     = element(split("/", var.kms_key_id), 5)
  location = element(split("/", var.kms_key_id), 3)
  project  = element(split("/", var.kms_key_id), 1)
}

# Data source to validate/read the provided key
data "google_kms_crypto_key" "cmek_crypto_key" {
  name     = element(split("/", var.kms_key_id), 7)
  key_ring = join("/", slice(split("/", var.kms_key_id), 0, 6))
}

# ---------------------------------------------------------------------------- #
# Gemini Enterprise CMEK Crypto Key
# ---------------------------------------------------------------------------- #
# This Crypto Key will be used to encrypt/decrypt Gemini Enterprise Data Stores
# (i.e. Cloud Storage, BigQuery) and Session data
resource "google_kms_crypto_key" "resources" {
  count           = var.create_resource_keys ? 1 : 0
  name            = "gemini-enterprise-cmek-key"
  key_ring        = data.google_kms_key_ring.cmek_key_ring.id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = local.kms_rotation_period # 90 days

  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "HSM"
  }

  # lifecycle {
  #   prevent_destroy = true
  # }
}

# ---------------------------------------------------------------------------- #
# US Multi-Region Key (Conditional)
# ---------------------------------------------------------------------------- #
# Created ONLY if geolocation is "us" AND the provided/resource key is NOT in "us".
# Discovery Engine requires a key in the "us" multi-region for "us" data stores.
resource "google_kms_key_ring" "us_key_ring" {
  count    = var.geolocation == "us" && data.google_kms_key_ring.cmek_key_ring.location != "us" ? 1 : 0
  name     = "gemini-enterprise-us-keyring"
  location = "us"
  project  = var.main_project_id
}

resource "google_kms_crypto_key" "us_crypto_key" {
  count           = var.geolocation == "us" && data.google_kms_key_ring.cmek_key_ring.location != "us" ? 1 : 0
  name            = "gemini-enterprise-us-key"
  key_ring        = google_kms_key_ring.us_key_ring[0].id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = local.kms_rotation_period

  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "HSM"
  }
}

# ---------------------------------------------------------------------------- #
# Gemini Enterprise CMEK IAM: Grant Discovery Engine Service Agent access
resource "google_kms_crypto_key_iam_member" "discoveryengine_sa_kms_access" {

  crypto_key_id = local.cmek_key_id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-discoveryengine.iam.gserviceaccount.com"

  depends_on = [
    google_project_service_identity.discoveryengine,
    time_sleep.wait_for_services
  ]
}

resource "google_kms_crypto_key_iam_member" "discoveryengine_sa_us_kms_access" {
  count         = var.geolocation == "us" && data.google_kms_key_ring.cmek_key_ring.location != "us" ? 1 : 0
  crypto_key_id = google_kms_crypto_key.us_crypto_key[0].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-discoveryengine.iam.gserviceaccount.com"

  depends_on = [
    google_project_service_identity.discoveryengine,
    time_sleep.wait_for_services
  ]
}

# ---------------------------------------------------------------------------- #
# Gemini Enterprise CMEK IAM: Grant Cloud Storage Service Agent access
resource "google_kms_crypto_key_iam_member" "gcs_sa_kms_access" {

  crypto_key_id = local.cmek_key_id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project.number}@gs-project-accounts.iam.gserviceaccount.com"

  depends_on = [
    google_project_service_identity.storage,
    time_sleep.wait_for_services
  ]
}

resource "google_kms_crypto_key_iam_member" "gcs_sa_us_kms_access" {
  count         = var.geolocation == "us" && data.google_kms_key_ring.cmek_key_ring.location != "us" ? 1 : 0
  crypto_key_id = google_kms_crypto_key.us_crypto_key[0].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project.number}@gs-project-accounts.iam.gserviceaccount.com"

  depends_on = [
    google_project_service_identity.storage,
    time_sleep.wait_for_services
  ]
}

# ---------------------------------------------------------------------------- #
# Gemini Enterprise CMEK IAM: Grant BigQuery Service Agent access
resource "google_kms_crypto_key_iam_member" "bq_sa_kms_access" {

  crypto_key_id = local.cmek_key_id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:bq-${data.google_project.project.number}@bigquery-encryption.iam.gserviceaccount.com"

  depends_on = [
    google_project_service_identity.bigquery,
    time_sleep.wait_for_services
  ]
}

resource "google_kms_crypto_key_iam_member" "bq_sa_us_kms_access" {
  count         = var.geolocation == "us" && data.google_kms_key_ring.cmek_key_ring.location != "us" ? 1 : 0
  crypto_key_id = google_kms_crypto_key.us_crypto_key[0].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:bq-${data.google_project.project.number}@bigquery-encryption.iam.gserviceaccount.com"

  depends_on = [
    google_project_service_identity.bigquery,
    time_sleep.wait_for_services
  ]
}