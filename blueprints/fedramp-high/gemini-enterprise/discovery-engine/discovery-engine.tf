terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.1"
    }
  }
}

# Copyright 2024 Google LLC
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

# Create the KMS key ring and crypto key for CMEK
resource "google_kms_key_ring" "cmek_key_ring" {
  project  = var.main_project_id
  name     = "gemini-enterprise-cmek-keyring"
  location = var.geolocation
}

resource "google_kms_crypto_key" "cmek_crypto_key" {
  name     = "gemini-enterprise-cmek-key"
  key_ring = google_kms_key_ring.cmek_key_ring.id
  purpose  = "ENCRYPT_DECRYPT"
  rotation_period = "7776000s" # 90 days

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
}

# ---------------------------------------------------------------------------- #
# Grant GCS Service Agent access to the KMS key
resource "google_kms_crypto_key_iam_member" "gcs_sa_kms_access" {
  crypto_key_id = google_kms_crypto_key.cmek_crypto_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.main.number}@gs-project-accounts.iam.gserviceaccount.com"
}

# ---------------------------------------------------------------------------- #
# ---------------------------------------------------------------------------- #

# GCS Bucket for Discovery Engine Data Source
resource "google_storage_bucket" "agent_space_data" {
  project                     = var.main_project_id
  name                        = "${var.main_project_id}-agent-space-gcs-data"
  location                    = var.geolocation
  uniform_bucket_level_access = true
  force_destroy               = false # Set to true only for non-production

  encryption {
    default_kms_key_name = google_kms_crypto_key.cmek_crypto_key.id
  }

  lifecycle_rule {
    condition {
      age = 30 # Example: delete objects older than 30 days
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    environment = "prod"
    service     = "agent-space-gcs"
  }

  depends_on = [
    google_kms_crypto_key_iam_member.gcs_sa_kms_access
  ]
}

# Discovery Engine Data Store for GCS
resource "google_discovery_engine_data_store" "agent_space_gcs_ds" {
  project       = var.main_project_id
  location      = var.geolocation # Must match the Data Store and Engine location
  data_store_id = "agent-space-gcs-data-store"
  display_name  = "Agent Space GCS Data Store"
  industry_vertical = "GENERIC"
  content_config    = "CONTENT_REQUIRED"
  solution_types  = ["SOLUTION_TYPE_SEARCH"]
  # TODO: Uncomment once Discovery Engine KMS bug is fixed
  # kms_key_name  = google_kms_crypto_key.cmek_crypto_key.id
  provider      = google-beta

  document_processing_config {
    default_parsing_config  {
      digital_parsing_config {}
    }
  }

  depends_on = [
    google_kms_crypto_key_iam_member.discoveryengine_sa_kms_access,
    google_kms_crypto_key_iam_member.gcs_sa_kms_access,
    google_kms_crypto_key.cmek_crypto_key,
    google_project_service.services,
  ]
}

# Discovery Engine Search Engine for GCS
resource "google_discovery_engine_search_engine" "agent_space_gcs_se" {
  project        = var.main_project_id
  location       = var.geolocation # Must match the Data Store location
  collection_id  = "default_collection"
  engine_id      = "agent-space-gcs-search-engine"
  display_name   = "Agent Space GCS Search Engine"
  data_store_ids = [google_discovery_engine_data_store.agent_space_gcs_ds.data_store_id] # Initially no data stores
  app_type       = "APP_TYPE_INTRANET"
  # disable_analytics = true

  search_engine_config {
    search_tier    = "SEARCH_TIER_ENTERPRISE"
    search_add_ons = ["SEARCH_ADD_ON_LLM"]
  }

  common_config {
    company_name = "Department of Technology"
  }

 # Addition of features via IL5 compliant configuration states
  features = {
    agent-gallery             = "FEATURE_STATE_OFF"
    no-code-agent-builder     = "FEATURE_STATE_OFF"
    prompt-gallery            = "FEATURE_STATE_OFF"
    model-selector            = "FEATURE_STATE_ON"
    notebook-lm               = "FEATURE_STATE_OFF"
    people-search             = "FEATURE_STATE_OFF"
    people-search-org-chart   = "FEATURE_STATE_OFF"
    bi-directional-audio      = "FEATURE_STATE_OFF"
    feedback                  = "FEATURE_STATE_OFF"
    session-sharing           = "FEATURE_STATE_OFF"
    personalization-memory    = "FEATURE_STATE_OFF"
    disable-agent-sharing     = "FEATURE_STATE_ON"
    disable-image-generation  = "FEATURE_STATE_ON"
    disable-video-generation  = "FEATURE_STATE_ON"
    disable-onedrive-upload   = "FEATURE_STATE_ON"
    disable-talk-to-content   = "FEATURE_STATE_ON"
    disable-google-drive-upload = "FEATURE_STATE_ON"
  }
  # not supported as of 10/22
  # knowledge_graph_config {
  #   enable_private_knowledge_graph = false
  # }

  industry_vertical = "GENERIC"
  provider = google-beta

  depends_on = [google_discovery_engine_data_store.agent_space_gcs_ds]
}

# To import data from the GCS bucket to the DataStore, run a command like this after terraform apply:
# gcloud discovery-engine data-stores import ${google_discovery_engine_data_store.agent_space_gcs_ds.id} \
#   --project=${var.main_project_id} \
#   --location=${var.discovery_engine_location} \
#   --gcs-source=gs://${google_storage_bucket.agent_space_data.name}/* \
#   --data-schema=content

# ---------------------------------------------------------------------------- #
#  Sample BigQuery Setup for Connector                                         #
# ---------------------------------------------------------------------------- #

resource "google_bigquery_dataset" "agent_space_sample_ds" {
  project     = var.main_project_id
  dataset_id  = "agent_space_sample_data"
  friendly_name = "Agent Space Sample Data"
  description = "Sample dataset for Discovery Engine connector"
  location    = var.region # Or a more specific multi-region if required by BQ
}

resource "google_bigquery_table" "agent_space_sample_table" {
  project    = var.main_project_id
  dataset_id = google_bigquery_dataset.agent_space_sample_ds.dataset_id
  table_id   = "sample_documents"
  deletion_protection = false

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
}

# ---------------------------------------------------------------------------- #
#  Setup 2: Discovery Engine with BigQuery Connector                           #
# ---------------------------------------------------------------------------- #

resource "google_discovery_engine_data_connector" "agent_space_bq_connector" {
  project     = var.main_project_id
  location      = var.geolocation # Ensure this is "us", "eu", or "global"
  collection_id = "agent-space-bq-collection"
  collection_display_name = "Agent Space BigQuery Collection"
  data_source = "bigquery"

  params = {
    instance_uri = "projects/${var.main_project_id}/datasets/${google_bigquery_dataset.agent_space_sample_ds.dataset_id}/tables/${google_bigquery_table.agent_space_sample_table.table_id}"
  }

  entities {
    entity_name = google_bigquery_table.agent_space_sample_table.table_id
    # Example key property mappings:
    # key_property_mappings = {
    #   "title" : "title",
    #   "description" : "description"
    # }

  }

  refresh_interval = "86400s" # Daily
  # TODO: Uncomment once Discovery Engine KMS bug is fixed
  # kms_key_name = google_kms_crypto_key.cmek_crypto_key.id
  provider = google-beta

  depends_on = [
    google_kms_crypto_key_iam_member.discoveryengine_sa_kms_access,
    google_kms_crypto_key_iam_member.gcs_sa_kms_access,
    google_kms_crypto_key.cmek_crypto_key,
    google_project_service.services,
    google_bigquery_table.agent_space_sample_table
  ]
}

# To use this connector with your own BigQuery table:
# 1. Ensure the BigQuery table exists in the var.main_project_id project.
# 2. Update the 'params' block above:
#    - Set 'dataset_id' to your BigQuery dataset ID.
#    - Set 'table_id' to your BigQuery table ID.
# 3. Update the 'entities' block above:
#    - Set 'entity_name' to your BigQuery table ID.
#    - Configure 'key_property_mappings' to map columns in your table to Discovery Engine schema fields (e.g., title, description).
# 4. Remove the sample BigQuery resources (agent_space_sample_ds and agent_space_sample_table) from this file.
# 5. Adjust the 'depends_on' for the connector if you removed the sample table resource.

# Add a delay to allow the DataStore to be created by the connector, which happens behind the scenes for data connector creation automatically.
resource "time_sleep" "wait_for_bq_datastore" {
  create_duration = "120s"

  depends_on = [google_discovery_engine_data_connector.agent_space_bq_connector]
}

# Discovery Engine Search Engine for BigQuery Connector
resource "google_discovery_engine_search_engine" "agent_space_bq_se" {
  project        = var.main_project_id
  location       = var.geolocation # Must be "us", "eu", or "global"
  collection_id  = "default_collection" # This must be default_collection, even if your collection_id for your created connector resource is different.
  engine_id      = "agent-space-bq-search-engine"
  display_name   = "Agent Space BigQuery Search Engine"
  # Dynamically get the DataStore ID created by the connector
  data_store_ids = [basename(google_discovery_engine_data_connector.agent_space_bq_connector.entities[0].data_store)]
  app_type = "APP_TYPE_INTRANET"

  search_engine_config {
    search_tier    = "SEARCH_TIER_ENTERPRISE"
    search_add_ons = ["SEARCH_ADD_ON_LLM"]
  }
  common_config {
    company_name = "Department of Technology"
    }

  features = {
    agent-gallery             = "FEATURE_STATE_OFF"
    # no_code_agent_builder     = "FEATURE_STATE_OFF"
    # prompt_gallery            = "FEATURE_STATE_OFF"
    # model_selector            = "FEATURE_STATE_ON"
    # notebook_lm               = "FEATURE_STATE_OFF"
    # people_search             = "FEATURE_STATE_OFF"
    # people_search_org_chart   = "FEATURE_STATE_OFF"
    # bi_directional_audio      = "FEATURE_STATE_OFF"
    # feedback                  = "FEATURE_STATE_OFF"
    # session_sharing           = "FEATURE_STATE_OFF"
    # personalization_memory    = "FEATURE_STATE_OFF"
    # disable_agent_sharing     = "FEATURE_STATE_ON"
    # disable_image_generation  = "FEATURE_STATE_ON"
    # disable_video_generation  = "FEATURE_STATE_ON"
    # disable_onedrive_upload   = "FEATURE_STATE_ON"
    # disable_talk_to_content   = "FEATURE_STATE_ON"
    # disable_google_drive_upload = "FEATURE_STATE_ON"
  }

  industry_vertical = "GENERIC"
  provider = google-beta
  # disable_analytics = true

  depends_on = [
    time_sleep.wait_for_bq_datastore,
    google_discovery_engine_data_connector.agent_space_bq_connector
  ]
}


        #  "features": {
        #     "agent-gallery": "FEATURE_STATE_OFF",
        #     "no-code-agent-builder": "FEATURE_STATE_OFF",
        #     "prompt-gallery": "FEATURE_STATE_OFF",
        #     "model-selector": "FEATURE_STATE_ON",
        #     "notebook-lm": "FEATURE_STATE_OFF",
        #     "people-search": "FEATURE_STATE_OFF",
        #     "people-search-org-chart": "FEATURE_STATE_OFF",
        #     "bi-directional-audio": "FEATURE_STATE_OFF",
        #     "feedback": "FEATURE_STATE_OFF",
        #     "session-sharing": "FEATURE_STATE_OFF",
        #     "personalization-memory": "FEATURE_STATE_OFF",
        #     "disable-agent-sharing": "FEATURE_STATE_ON",
        #     "disable-image-generation":"FEATURE_STATE_ON",
        #     "disable-video-generation":"FEATURE_STATE_ON",
        #     "disable-onedrive-upload":"FEATURE_STATE_ON",
        #     "disable-talk-to-content":"FEATURE_STATE_ON",
        #     "disable-google-drive-upload":"FEATURE_STATE_ON"
        #  },


# ---------------------------------------------------------------------------- #
#  Common ACL Config                                                           #
# ---------------------------------------------------------------------------- #

# Discovery Engine ACL Config First-party
resource "google_discovery_engine_acl_config" "agent_space_acl_config" {
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

output "gcs_discovery_engine_data_store_name" {
  description = "The full resource name of the GCS Discovery Engine Data Store."
  value       = google_discovery_engine_data_store.agent_space_gcs_ds.name
}

output "gcs_agent_space_data_bucket_name" {
  description = "The name of the GCS bucket created for Agent Space data."
  value       = google_storage_bucket.agent_space_data.name
}

output "gcs_discovery_engine_search_engine_name" {
  description = "The name of the GCS Discovery Engine Search Engine."
  value       = google_discovery_engine_search_engine.agent_space_gcs_se.name
}

output "bq_discovery_engine_collection_id" {
  description = "The ID of the BigQuery Discovery Engine Collection."
  value       = google_discovery_engine_data_connector.agent_space_bq_connector.collection_id
}

output "bq_discovery_engine_search_engine_name" {
  description = "The name of the BigQuery Discovery Engine Search Engine."
  value       = google_discovery_engine_search_engine.agent_space_bq_se.name
}
