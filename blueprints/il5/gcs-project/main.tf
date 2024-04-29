# Google Project
# Google Cloud Storage Module 

# Storage bucket with dual-region placement and encryption
resource "google_storage_bucket" "private" {
  name                        = var.bucket_name
  location                    = "us"
  project                     = var.project_id
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  encryption {
    default_kms_key_name = google_kms_crypto_key.crypto_key.id
  }

  custom_placement_config {
    data_locations = var.dual_locations
  }

  autoclass {
    enabled = true
  }
  depends_on = [google_project_iam_binding.project]
}

resource "google_kms_key_ring" "key_ring" {
  name     = var.key_ring_name
  location = "us"
}

resource "google_kms_crypto_key" "crypto_key" {
  name            = var.key_name
  key_ring        = google_kms_key_ring.key_ring.id
  rotation_period = "100000s"
}

data "google_project" "current" {
}

locals {
  cloud_storage_service_account = "service-${data.google_project.current.number}@gs-project-accounts.iam.gserviceaccount.com"
}

resource "google_project_iam_binding" "project" {
  project = data.google_project.current.id
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members = [
    "serviceAccount:${local.cloud_storage_service_account}",
  ]
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
  bucket      = google_storage_bucket.private.name
  policy_data = data.google_iam_policy.admin.policy_data
}