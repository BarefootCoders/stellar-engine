/**
 * Copyright 2024 Google LLC
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

#Terraform Provider for Google Cloud Platform
provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_project" "current" {}
data "google_bigquery_default_service_account" "bq_sa" {}

module "bigquery-dataset" {
  source         = "../../../modules/bigquery-dataset"
  location       = "us-east4"
  project_id     = var.project_id
  id             = var.id
  description    = "This dataset has customer managed encrytped keys, is updated in real-time, and accessed by restricted roles."
  encryption_key = module.kms.keys.default.id

  depends_on = [module.kms]
}

#Google KMS Module
module "kms" {
  source     = "../../../modules/kms"
  project_id = var.project_id
  keys       = var.keys
  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = ["serviceAccount:${data.google_bigquery_default_service_account.bq_sa.email}"]
  }
  keyring = var.keyring
}
