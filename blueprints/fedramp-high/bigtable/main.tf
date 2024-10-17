# Fetch the provided encryption key directly from the user's input
locals {
  kms_key_id = var.key_name
}

data "google_project" "project" {}

# Service Identity is required to enable encryption for the tables in the bigtable instance, without this account only the clusters will be encrypted
resource "google_project_service_identity" "bigtable_sa" {
  provider = google-beta

  project = var.project_id
  service = "bigtableadmin.googleapis.com"
}

resource "google_project_iam_binding" "bigtable_kms_access" {
  project = var.project_id
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:${google_project_service_identity.bigtable_sa.email}",
  ]
}

# Create bigtable instance
module "bigtable-instance" {
  source         = "../../../modules/bigtable-instance"
  project_id     = var.project_id
  name           = var.instance_name
  encryption_key = local.kms_key_id
  clusters = {
    (var.cluster_id) = {
      cluster_id   = var.cluster_id
      zone         = var.zone
      num_nodes    = var.num_nodes
      storage_type = var.storage_type
    }
  }
  tables              = var.table
  deletion_protection = false
}
