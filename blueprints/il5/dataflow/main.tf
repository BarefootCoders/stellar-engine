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

# Create the GCS service account
resource "google_service_account" "gcs" {
  account_id   = "gcs-service-account"
  display_name = "GCS Service Account"
  project      = var.project_id
}

# Bind the necessary roles to the GCS service account
resource "google_project_iam_member" "gcs_storage_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.gcs.email}"
}

resource "google_project_iam_member" "gcs_storage_creator" {
  project = var.project_id
  role    = "roles/storage.objectCreator"
  member  = "serviceAccount:${google_service_account.gcs.email}"
}

# Create the Dataflow service account
resource "google_service_account" "dataflow" {
  account_id   = var.dataflow_service_account_id
  display_name = "Dataflow Service Account"
  project      = var.project_id
}

# Bind the necessary roles to the Dataflow service account
resource "google_project_iam_member" "dataflow_worker" {
  project = var.project_id
  role    = "roles/dataflow.worker"
  member  = "serviceAccount:${google_service_account.dataflow.email}"
}

resource "google_project_iam_member" "dataflow_network_user" {
  project = var.project_id
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:${google_service_account.dataflow.email}"
}

resource "google_project_iam_member" "dataflow_storage_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.dataflow.email}"
}

resource "google_project_iam_member" "dataflow_storage_creator" {
  project = var.project_id
  role    = "roles/storage.objectCreator"
  member  = "serviceAccount:${google_service_account.dataflow.email}"
}

resource "google_project_iam_member" "dataflow_pubsub_subscriber" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.dataflow.email}"
}

resource "google_project_iam_member" "dataflow_pubsub_viewer" {
  project = var.project_id
  role    = "roles/pubsub.viewer"
  member  = "serviceAccount:${google_service_account.dataflow.email}"
}

resource "google_project_iam_member" "dataflow_bigquery_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.dataflow.email}"
}

resource "google_project_iam_member" "dataflow_bigquery_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.dataflow.email}"
}

# Google Cloud Storage Module
module "gcs" {
  source         = "../../../modules/gcs"
  prefix         = var.prefix
  project_id     = var.project_id
  location       = var.region
  storage_class  = var.storage_class
  encryption_key = module.kms.keys.key-dataflow-job.id
  name           = var.bucket_name
}

# Google KMS Module
module "kms" {
  source     = "../../../modules/kms"
  project_id = var.project_id
  keys       = var.keys
  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = concat(
      [
        "serviceAccount:${google_service_account.dataflow.email}",
        "serviceAccount:${google_service_account.gcs.email}",
        "user:${var.email}"
      ]
    )
  }
  keyring = var.keyring
}

# BigQuery Dataset
resource "google_bigquery_dataset" "dataset" {
  dataset_id  = var.dataset_id
  project     = var.project_id
  location    = var.location
  description = "This dataset has customer managed encrypted keys."
}

# BigQuery Table
resource "google_bigquery_table" "table" {
  table_id   = var.bigquery_table_id
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  project    = var.project_id
}

# Pub/Sub Topic
resource "google_pubsub_topic" "topic" {
  name         = "pb-topic"
  project      = var.project_id
  kms_key_name = module.kms.keys.key-dataflow-job.id
}

# Pub/Sub Subscription
resource "google_pubsub_subscription" "subscription" {
  name    = "pb-topic-subscription"
  topic   = google_pubsub_topic.topic.name
  project = var.project_id
}

# Dataflow Job
resource "google_dataflow_job" "job" {
  name                  = var.dataflow_name
  template_gcs_path     = var.template_gcs_path
  temp_gcs_location     = var.temp_gcs_location
  service_account_email = google_service_account.dataflow.email
  project               = var.project_id
  region                = var.region
  network               = var.network_name
  zone                  = var.zone
  parameters = {
    inputTopic      = "projects/${var.project_id}/topics/${google_pubsub_topic.topic.name}"
    outputTableSpec = "${var.project_id}:${google_bigquery_dataset.dataset.dataset_id}.${google_bigquery_table.table.table_id}"
  }
}






