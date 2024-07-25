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

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_project" "current" {}

resource "google_service_account" "dataflow_worker" {
  account_id   = var.project_id
  display_name = "Dataflow Worker Storage Account"
}


module "kms" {
  source     = "../../../modules/kms"
  project_id = var.project_id
  keys       = var.keys

  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = concat(
      [
        "serviceAccount:service-${data.google_project.current.number}@compute-system.iam.gserviceaccount.com",                 # Compute Service Account Required by Dataflow
        "serviceAccount:service-${data.google_project.current.number}@dataflow-service-producer-prod.iam.gserviceaccount.com", # Dataflow Service Account
        "serviceAccount:service-${data.google_project.current.number}@gs-project-accounts.iam.gserviceaccount.com"             # GCS Service Account
      ]
    )
  }

  keyring = var.keyring
}

module "gcs" {
  source         = "../../../modules/gcs"
  prefix         = var.prefix
  project_id     = var.project_id
  location       = var.region
  storage_class  = var.storage_class
  encryption_key = module.kms.keys.dataflow-job.id
  name           = var.bucket_name

  iam = {
    "roles/storage.objectAdmin" = concat(
      [
        "serviceAccount:${google_service_account.dataflow_worker.email}" # Worker Service account
      ]
    )
  }

  force_destroy = true

  depends_on = [module.kms]
}

resource "google_project_iam_member" "dataflow_worker" {
  project = var.project_id
  role    = "roles/dataflow.worker"
  member  = "serviceAccount:${google_service_account.dataflow_worker.email}"
}

resource "google_dataflow_job" "job" {
  project = var.project_id
  name    = "dataflow-job"
  region  = var.region
  zone    = var.zone

  template_gcs_path = var.template_gcs_path
  temp_gcs_location = "gs://${module.gcs.bucket.name}/temp"

  service_account_email = google_service_account.dataflow_worker.email

  parameters = var.parameters

  network          = var.network
  subnetwork       = var.subnet
  ip_configuration = "WORKER_IP_PRIVATE" # Required for IL5

  kms_key_name = module.kms.keys.dataflow-job.id

  depends_on = [module.kms, module.gcs, google_project_iam_member.dataflow_worker]
}
