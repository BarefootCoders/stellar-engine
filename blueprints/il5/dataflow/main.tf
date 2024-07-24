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

# Terraform Provider for Google Cloud Platform
provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_project" "current" {}

# data "google_compute_default_service_account" "default" {}

# Create the Dataflow service account
# resource "google_service_account" "dataflow" {
#   account_id   = var.dataflow_service_account_id
#   display_name = "Dataflow Service Account"
#   project      = var.project_id
# }

# Bind the necessary roles to the Dataflow service account
resource "google_project_iam_member" "dataflow_worker" {
  project = var.project_id
  role    = "roles/dataflow.admin"
  # member  = "serviceAccount:${google_service_account.dataflow.email}"
  member = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
  # member = data.google_compute_default_service_account.default.member
  # member = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "dataflow_network_user" {
  project = var.project_id
  role    = "roles/compute.admin"
  member  = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
  # member  = "serviceAccount:${google_service_account.dataflow.email}"
  # member = data.google_compute_default_service_account.default.member
  # member = "serviceAccount:service-${data.google_project.current.number}@dataflow-service-producer-prod.iam.gserviceaccount.com
}

### TODO - replace in bigquery iam module
resource "google_project_iam_member" "dataflow_bigquery_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  # member  = "serviceAccount:${google_service_account.dataflow.email}"
  member = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

### TODO - replace in bigquery iam module
resource "google_project_iam_member" "dataflow_bigquery_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  # member  = "serviceAccount:${google_service_account.dataflow.email}"
  member = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

# Google Cloud Storage Module
module "gcs" {
  source         = "../../../modules/gcs"
  prefix         = var.prefix
  project_id     = var.project_id
  location       = var.region
  storage_class  = var.storage_class
  encryption_key = module.kms.keys.dataflow-job.id
  name           = var.bucket_name

  iam = {
    "roles/storage.objectViewer" = concat(
      [
        "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com",
        # "serviceAccount:${google_service_account.dataflow.email}",
        # "serviceAccount:service-${data.google_project.current.number}@gs-project-accounts.iam.gserviceaccount.com"
      ]
    ),
    "roles/storage.objectCreator" = concat(
      [
        "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com",
        # "serviceAccount:${google_service_account.dataflow.email}",
        # "serviceAccount:service-${data.google_project.current.number}@gs-project-accounts.iam.gserviceaccount.com"
      ]
    )
  }
  depends_on = [module.kms]
}

# Google KMS Module
module "kms" {
  source     = "../../../modules/kms"
  project_id = var.project_id
  keys       = var.keys
  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = concat(
      [
        # "serviceAccount:${google_service_account.dataflow.email}",
        "serviceAccount:service-${data.google_project.current.number}@dataflow-service-producer-prod.iam.gserviceaccount.com", # Dataflow Service Account
        "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com",                          # Worker service account
        "serviceAccount:service-${data.google_project.current.number}@gs-project-accounts.iam.gserviceaccount.com",
        "serviceAccount:service-${data.google_project.current.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
      ]
    )
  }
  keyring = var.keyring
}

## TODO - change to use BQ module
# BigQuery Dataset
resource "google_bigquery_dataset" "dataset" {
  dataset_id = var.dataset_id
  project    = var.project_id
  location   = var.location
}

## TODO - change to use BQ module
# BigQuery Table
resource "google_bigquery_table" "table" {
  table_id   = var.bigquery_table_id
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  project    = var.project_id

  deletion_protection = false
}


module "pubsub" {
  source        = "../../../modules/pubsub"
  project_id    = var.project_id
  name          = "df-topic"
  regions       = [var.region]
  kms_key       = module.kms.keys.dataflow-job.id
  depends_on    = [module.kms]
  subscriptions = {}

  iam = {
    "roles/pubsub.subscriber" = concat(
      [
        "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com",
        # "serviceAccount:${google_service_account.dataflow.email}",
        "serviceAccount:service-${data.google_project.current.number}@gs-project-accounts.iam.gserviceaccount.com"
      ]
    ),
    "roles/pubsub.viewer" = concat(
      [
        "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com",
        # "serviceAccount:${google_service_account.dataflow.email}",
        "serviceAccount:service-${data.google_project.current.number}@gs-project-accounts.iam.gserviceaccount.com"
      ]
    )
  }
}

# 

# Dataflow Job
resource "google_dataflow_job" "job" {
  name              = var.dataflow_name
  template_gcs_path = var.template_gcs_path
  temp_gcs_location = "gs://${module.gcs.bucket.name}/temp"
  # service_account_email = google_service_account.dataflow.email
  project      = var.project_id
  region       = var.region
  network      = var.network_name
  zone         = var.zone
  kms_key_name = module.kms.keys.dataflow-job.id
  parameters = {
    inputTopic      = "projects/${var.project_id}/topics/${module.pubsub.topic.name}"
    outputTableSpec = "${var.project_id}:${google_bigquery_dataset.dataset.dataset_id}.${google_bigquery_table.table.table_id}"
  }
  depends_on = [module.gcs, module.kms]
}
