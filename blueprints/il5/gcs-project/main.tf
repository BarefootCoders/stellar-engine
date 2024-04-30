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
/*
module "kms" {
  source     = "../../../modules/kms"
  project_id = var.project_id
  keyring    = var.keyring
  keys       = var.keys
}
*/
data "google_project" "current" {
}

locals {
  cloud_storage_service_account = "service-${data.google_project.current.number}@gs-project-accounts.iam.gserviceaccount.com"
}

module "kms" {
  source     = "../../../modules/kms"
  project_id = var.project_id
  keys       = var.keys
  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = ["user:${var.email}",  "serviceAccount:${local.cloud_storage_service_account}"]
  }
  keyring = var.keyring  
}
    

data "google_iam_policy" "admin" {
  binding {
    role = "roles/storage.admin"
    members = [
      "user:${var.email}"
    ]
  }
}