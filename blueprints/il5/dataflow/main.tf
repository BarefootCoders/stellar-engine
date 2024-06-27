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

#Current Project
data "google_project" "current" {}

#Existing gcs account
data "google_storage_project_service_account" "gcs_account" {}

#Existing BigQuery dataset
data "google_bigquery_dataset" "dataset" {
  dataset_id = var.bigquery_dataset_id
  project    = var.project_id
}

#Existing Pub/Sub Topic
data "google_pubsub_topic" "topic" {
  name    = var.pubsub_topic_name
  project = var.project_id
}
#Existing Pub/Sub Subscription
data "google_pubsub_subscription" "subscription" {
  name    = var.pubsub_subscription_name
  project = var.project_id
}

resource "google_kms_crypto_key_iam_binding" "binding" {
  crypto_key_id = module.kms.keys.key-dataflow.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members       = [data.google_storage_project_service_account.gcs_account.member]
}

# Create the Dataflow service account
resource "google_service_account" "dataflow" {
  account_id   = var.dataflow_service_account_id
  display_name = "Dataflow Service Account"
  project      = var.project_id
}

module "gcs" {
  source         = "../../../modules/gcs"
  prefix         = var.prefix
  project_id     = var.project_id
  location       = var.region
  storage_class  = var.storage_class
  encryption_key = module.kms.keys.key-dataflow.id
  name           = var.bucket_name
}

#Google KMS Module
module "kms" {
  source     = "../../../modules/kms"
  project_id = var.project_id
  keys       = var.keys

  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = concat(
      [
        "serviceAccount:${google_service_account.dataflow.email}",
        "serviceAccount:service-${data.google_project.current.number}@compute-system.iam.gserviceaccount.com",
        "user:${var.email}"
    ])
  }
  keyring = var.keyring
}

# Terraform Dataflow job
module "dataflow_job" {
  source                = "terraform-google-modules/dataflow/google"
  version               = "~> 1.0"
  project_id            = var.project_id
  name                  = var.dataflow_name
  template_gcs_path     = var.template_gcs_path
  temp_gcs_location     = var.temp_gcs_location
  region                = var.region
  service_account_email = google_service_account.dataflow.email
  zone                  = var.zone
  parameters = {
    inputTopic      = "projects/${var.project_id}/topics/${var.pubsub_topic_name}"
    outputTableSpec = "${var.project_id}:${var.bigquery_dataset_id}.${var.bigquery_table_id}"
  }
}

#Granting dataflow access to BigQuery dataset
resource "google_project_iam_binding" "dataflow_bigquery_access" {
  project = var.project_id
  role    = "roles/bigquery.user"
  members = [
    "serviceAccount:${google_service_account.dataflow.email}"
  ]
}

#Granting dataflow access to pub/sub 
resource "google_project_iam_binding" "dataflow_pubsub_access" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  members = [
    "serviceAccount:${google_service_account.dataflow.email}"
  ]
}
