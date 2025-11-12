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
  gcs_lifecycle_age   = 30
  bq_connector_refresh_interval = "86400s" # Daily
  wait_for_bq_datastore_duration = "120s"
}

# Create the KMS key ring and crypto key for CMEK
resource "google_kms_key_ring" "cmek_key_ring" {
  project  = var.main_project_id
  name     = "gemini-enterprise-cmek-keyring"
  location = var.geolocation
}

resource "google_kms_crypto_key" "cmek_crypto_key" {
  # Change the name below to gemini-enterprise-cmek-key
  name     = "gemini-enterprise-cmek-key"
  key_ring = google_kms_key_ring.cmek_key_ring.id
  purpose  = "ENCRYPT_DECRYPT"
  rotation_period = local.kms_rotation_period # 90 days

  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "HSM"
  }

  lifecycle {
    # prevent_destroy = true
  }
}

# Get project details for the main project
data "google_project" "main" {
  project_id = var.main_project_id
}

# Grant Discovery Engine Service Agent access to the KMS key
resource "google_kms_crypto_key_iam_member" "discoveryengine_sa_kms_access" {
  crypto_key_id = google_kms_crypto_key.cmek_crypto_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.main.number}@gcp-sa-discoveryengine.iam.gserviceaccount.com"

  depends_on = [
    google_project_service_identity.discoveryengine,
    time_sleep.wait_for_services
  ]
}

# ---------------------------------------------------------------------------- #
# Grant GCS Service Agent access to the KMS key
resource "google_kms_crypto_key_iam_member" "gcs_sa_kms_access" {
  crypto_key_id = google_kms_crypto_key.cmek_crypto_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.main.number}@gs-project-accounts.iam.gserviceaccount.com"

  depends_on = [
    google_project_service_identity.storage,
    time_sleep.wait_for_services
  ]
}

# Grant BigQuery Service Agent access to the KMS key
resource "google_kms_crypto_key_iam_member" "bq_sa_kms_access" {
  crypto_key_id = google_kms_crypto_key.cmek_crypto_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:bq-${data.google_project.main.number}@bigquery-encryption.iam.gserviceaccount.com"
}

# ---------------------------------------------------------------------------- #
#  Discovery Engine CMEK Config                                              #
# ---------------------------------------------------------------------------- #

resource "google_discovery_engine_cmek_config" "default" {
  location       = var.geolocation # Should be "us"
  cmek_config_id = "default_cmek_config"
  kms_key        = google_kms_crypto_key.cmek_crypto_key.id
  set_default    = true
  provider       = google-beta

  depends_on = [
    google_kms_crypto_key_iam_member.discoveryengine_sa_kms_access,
    google_kms_crypto_key_iam_member.bq_sa_kms_access,
    google_kms_crypto_key_iam_member.gcs_sa_kms_access,
    time_sleep.wait_for_services,
  ]
}

# ---------------------------------------------------------------------------- #
# ---------------------------------------------------------------------------- #

# GCS Buckets for Discovery Engine Data Sources
resource "google_storage_bucket" "gemini_enterprise_data" {
  for_each = toset(var.gcs_data_store_names)

  project                     = var.main_project_id
  name                        = "${var.main_project_id}-${each.key}-data"
  location                    = var.geolocation
  uniform_bucket_level_access = true
  force_destroy               = false # Set to true only for non-production

  encryption {
    default_kms_key_name = google_kms_crypto_key.cmek_crypto_key.id
  }

  lifecycle_rule {
    condition {
      age = local.gcs_lifecycle_age # Example: delete objects older than 30 days
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    environment = var.gcs_label_environment
    service     = "gemini-enterprise-gcs"
    data_store  = each.key
  }

  depends_on = [
    google_kms_crypto_key_iam_member.gcs_sa_kms_access
  ]
}

# Discovery Engine Data Stores for GCS
resource "google_discovery_engine_data_store" "gemini_enterprise_gcs_ds" {
  for_each = toset(var.gcs_data_store_names)

  project       = var.main_project_id
  location      = var.geolocation # Must match the Data Store and Engine location
  data_store_id = "${each.key}-gcs-data-store"
  display_name  = "Gemini Enterprise GCS Data Store - ${each.key}"
  industry_vertical = "GENERIC"
  content_config    = "CONTENT_REQUIRED"
  solution_types  = ["SOLUTION_TYPE_SEARCH"]
  kms_key_name  = google_kms_crypto_key.cmek_crypto_key.id
  provider      = google-beta

  document_processing_config {
    default_parsing_config {
      digital_parsing_config {}
    }
  }

  depends_on = [
    google_discovery_engine_cmek_config.default,
    google_kms_crypto_key_iam_member.discoveryengine_sa_kms_access,
    google_kms_crypto_key_iam_member.gcs_sa_kms_access,
    google_kms_crypto_key.cmek_crypto_key,
    google_project_service.services,
    time_sleep.wait_for_services,
  ]
}

# ---------------------------------------------------------------------------- #
#  Dynamic BigQuery Setup for Connectors                                     #
# ---------------------------------------------------------------------------- #

locals {
  bq_configs = { for idx, config in var.bq_data_store_configs : idx => config }
}

resource "google_bigquery_dataset" "gemini_enterprise_bq_ds" {
  for_each = local.bq_configs

  project     = var.main_project_id
  dataset_id  = each.value.dataset_id
  friendly_name = "Gemini Enterprise Data - ${each.value.dataset_id}"
  description = "Dataset for Discovery Engine connector - ${each.value.dataset_id}"
  location    = var.geolocation # Or a more specific region specific location if desired

  default_encryption_configuration {
    kms_key_name = google_kms_crypto_key.cmek_crypto_key.id
  }
}

resource "google_bigquery_table" "gemini_enterprise_bq_table" {
  for_each = local.bq_configs

  project    = var.main_project_id
  dataset_id = google_bigquery_dataset.gemini_enterprise_bq_ds[each.key].dataset_id
  table_id   = each.value.table_id
  deletion_protection = false

  # Define a default schema, users can adapt this as needed
  schema = <<EOF
[
  {
    "name": "doc_id",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "Unique document ID"
  },
  {
    "name": "title",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Document title"
  },
  {
    "name": "description",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Document description or body"
  },
  {
    "name": "url",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Document URL"
  }
]
EOF

  depends_on = [google_bigquery_dataset.gemini_enterprise_bq_ds]
}

# ---------------------------------------------------------------------------- #
#  Dynamic Discovery Engine with BigQuery Connectors                         #
# ---------------------------------------------------------------------------- #

resource "google_discovery_engine_data_connector" "gemini_enterprise_bq_connector" {
  for_each = local.bq_configs

  project     = var.main_project_id
  location      = var.geolocation # Ensure this is "us", "eu", or "global"
  collection_id = "${each.value.dataset_id}-${each.value.table_id}-collection"
  collection_display_name = "Gemini Enterprise BQ Collection - ${each.value.dataset_id}"
  data_source = "bigquery"

  params = {
    instance_uri = "projects/${var.main_project_id}/datasets/${google_bigquery_dataset.gemini_enterprise_bq_ds[each.key].dataset_id}/tables/${google_bigquery_table.gemini_enterprise_bq_table[each.key].table_id}"
  }

  entities {
    entity_name = google_bigquery_table.gemini_enterprise_bq_table[each.key].table_id
    # Example key property mappings - users should customize this
    # key_property_mappings = {
    #   "title" : "title",
    #   "description" : "description"
    # }
  }

  refresh_interval = "86400s" # Daily
  kms_key_name = google_kms_crypto_key.cmek_crypto_key.id
  provider = google-beta

  depends_on = [
    google_discovery_engine_cmek_config.default,
    google_kms_crypto_key_iam_member.discoveryengine_sa_kms_access,
    google_kms_crypto_key_iam_member.gcs_sa_kms_access,
    google_kms_crypto_key.cmek_crypto_key,
    google_project_service.services,
    time_sleep.wait_for_services,
  ]
}

# Add a delay to allow the DataStore to be created by the connector
resource "time_sleep" "wait_for_bq_datastore" {
  for_each = local.bq_configs
  create_duration = "30s"
  depends_on = [google_discovery_engine_data_connector.gemini_enterprise_bq_connector]
}

# ---------------------------------------------------------------------------- #
#  Common ACL Config                                                           #
# ---------------------------------------------------------------------------- #

# Discovery Engine ACL Config First-party
resource "google_discovery_engine_acl_config" "gemini_enterprise_acl_config" {
  project  = var.main_project_id
  location = var.geolocation # Must match the connector location
  idp_config {
    idp_type = "GSUITE"
  }
  provider = google-beta
}

# ---------------------------------------------------------------------------- #
#  Outputs                                                                     #
# ---------------------------------------------------------------------------- #

output "gcs_discovery_engine_data_stores" {
  description = "A map of GCS Discovery Engine Data Store names and their full resource names."
  value       = { for k, v in google_discovery_engine_data_store.gemini_enterprise_gcs_ds : k => v.name }
}

output "gcs_gemini_enterprise_data_buckets" {
  description = "A map of GCS bucket names created for Gemini Enterprise data."
  value       = { for k, v in google_storage_bucket.gemini_enterprise_data : k => v.name }
}

output "bq_discovery_engine_connectors" {
  description = "A map of BigQuery Discovery Engine Connector IDs and their collection IDs."
  value       = { for k, v in google_discovery_engine_data_connector.gemini_enterprise_bq_connector : k => v.collection_id }
}

output "bq_discovery_engine_data_store_ids" {
  description = "A map of BigQuery Discovery Engine Data Store IDs created by the connectors."
  value       = { for k, v in google_discovery_engine_data_connector.gemini_enterprise_bq_connector : k => basename(v.entities[0].data_store) }
}