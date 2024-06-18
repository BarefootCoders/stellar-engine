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

# Custom service account with compute engine role  
resource "google_service_account" "compute" {
  account_id = var.compute_service_account_id
  project    = var.project_id
}

#Google KMS Module
module "kms" {
  source     = "../../../modules/kms"
  project_id = var.project_id
  keys       = var.keys

  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = concat(
      [
        "serviceAccount:${google_service_account.compute.email}",
        "serviceAccount:service-${data.google_project.current.number}@compute-system.iam.gserviceaccount.com",
        "user:${var.email}",
    ])
  }
  keyring = var.keyring
}

#Making dataflow bucket
resource "google_storage_bucket" "dataflow_bucket" {
  name                        = var.bucket_name
  location                    = var.region
  uniform_bucket_level_access = true
  encryption {
    default_kms_key_name = module.kms.keys.default.id
  }
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 25
    }
  }
}

#Using the terraform dataflow module
module "dataflow_job" {
  source                = "terraform-google-modules/dataflow/google"
  version               = "~> 1.0"
  project_id            = var.project_id
  name                  = var.name
  template_gcs_path     = var.template_gcs_path
  temp_gcs_location     = var.temp_gcs_location
  region                = var.region
  service_account_email = var.service_account_email
  zone                  = var.zone
}