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
data "google_compute_default_service_account" "default" {}

resource "google_project_iam_member" "dataflow_worker" {
  project = var.project_id
  role    = "roles/dataflow.worker"
  member  = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "dataflow_network_user" {
  project = var.project_id
  role    = "roles/compute.networkUser"
  # role = "roles/compute.admin"
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

  objects_to_upload = {
    sample-data = {
      name         = "sample.txt"
      source       = "input/sample.txt"
      content_type = "text/csv"
    }
  }

  force_destroy = true

  iam = {
    "roles/storage.objectViewer" = concat(
      [
        "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com",
      ]
    ),
    "roles/storage.objectCreator" = concat(
      [
        "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com",
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
        "serviceAccount:service-${data.google_project.current.number}@dataflow-service-producer-prod.iam.gserviceaccount.com", # Dataflow Service Account
        "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com",                          # Worker service account
        "serviceAccount:service-${data.google_project.current.number}@gs-project-accounts.iam.gserviceaccount.com",
        "serviceAccount:service-${data.google_project.current.number}@gcp-sa-pubsub.iam.gserviceaccount.com"]
    )
  }
  keyring = var.keyring
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
        # "serviceAccount:service-${data.google_project.current.number}@gs-project-accounts.iam.gserviceaccount.com"
      ]
    ),
    "roles/pubsub.viewer" = concat(
      [
        "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com",
        # "serviceAccount:service-${data.google_project.current.number}@gs-project-accounts.iam.gserviceaccount.com"
      ]
    )
  }
}

# Dataflow Job
resource "google_dataflow_job" "job" {
  name = var.dataflow_name
  # template_gcs_path = var.template_gcs_path
  template_gcs_path = "gs://dataflow-templates/latest/Word_Count"
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
