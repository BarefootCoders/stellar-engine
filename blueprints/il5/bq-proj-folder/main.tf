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
resource "google_kms_key_ring" "crypto_bq_keyring" {
  name     = var.keyring
  location = var.region
  project  = var.project_id
}
#Google KMS Module
module "kms" {
  source     = "../../../modules/kms"
  project_id = var.project_id
  keys       = var.keys
}
module "bigquery" {
  project_id                 = var.project_id
  source                     = "../../../modules/kms"
  dataset_id                 = var.dataset_id
  dataset_name               = var.dataset_name
  description                = "This dataset has customer managed encrytped keys, is updated in real-time, and accessed by restricted roles."
  delete_contents_on_destroy = var.delete_contents_on_destroy
  access                     = var.bigquery_access
  keyring                    = var.keyring
}








