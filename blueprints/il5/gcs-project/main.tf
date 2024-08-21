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

# Work on the Current Project
data "google_project" "current" {}

# Obtain the Cloud Storage Service Account
locals {
  cloud_storage_service_account = "service-${data.google_project.current.number}@gs-project-accounts.iam.gserviceaccount.com"
}

# Google Cloud Storage Module 
module "gcs" {
  source         = "../../../modules/gcs"
  prefix         = var.prefix
  project_id     = var.project_id
  location       = var.location
  storage_class  = var.storage_class
  encryption_key = module.kms.keys.default.id
  name           = var.name
  depends_on     = [module.kms]

  # CIS Compliance Benchmark 5.1
  public_access_prevention = var.public_access_prevention

  # CIS Compliance Benchmark 5.2
  uniform_bucket_level_access = var.uniform_bucket_level_access

  iam = {
    "roles/storage.admin" = ["user:${var.email}"]
  }
}

# Google KMS Module
module "kms" {
  source     = "../../../modules/kms"
  project_id = var.project_id
  keys       = var.keys
  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = ["serviceAccount:${local.cloud_storage_service_account}"]
  }
  keyring = var.keyring
}