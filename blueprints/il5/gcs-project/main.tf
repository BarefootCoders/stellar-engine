# Google Project
# Google Cloud Storage Module 
provider "google" {
  project = var.project_id
  region  = var.region

}
module "gcs" {
  source         = "../../../modules/gcs"
  prefix         = var.prefix
  project_id     = var.project_id
  location       = var.location
  storage_class  = var.storage_class
  encryption_key = module.kms.keys.default.id
  name           = var.name
}

module "kms" {
  source     = "../../../modules/kms"
  project_id = var.project_id
  keyring    = var.keyring
  keys       = var.keys
}
    

resource "google_project_iam_binding" "project" {
  project = data.google_project.current.id
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members = [
    "serviceAccount:${local.cloud_storage_service_account}",
  ]
}

data "google_project" "current" {
}

locals {
  cloud_storage_service_account = "service-${data.google_project.current.number}@gs-project-accounts.iam.gserviceaccount.com"
}


data "google_iam_policy" "admin" {
  binding {
    role = "roles/storage.admin"
    members = [
      "user:${var.email}"
    ]
  }
}

resource "google_storage_bucket_iam_policy" "policy" {
  bucket      = google_storage_bucket.bucket.name
  policy_data = data.google_iam_policy.admin.policy_data
}    