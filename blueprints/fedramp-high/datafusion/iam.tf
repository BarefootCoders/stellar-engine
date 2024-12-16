data "google_project" "current" {
  project_id = var.project_id
}

# Dataproc Integration Service Account
resource "google_service_account" "datafusion" {
  account_id   = "df-${var.project_id}"
  display_name = "Dataproc Worker Service Account"
}

resource "google_project_iam_member" "network_user_main" {
  project = var.project_id
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-datafusion.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "network_user_lz" {
  project = var.landing_project_id
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-datafusion.iam.gserviceaccount.com"
}

resource "google_kms_crypto_key_iam_binding" "datafusion" {
  crypto_key_id = var.kms_key
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members = [
    "serviceAccount:service-${data.google_project.current.number}@gcp-sa-datafusion.iam.gserviceaccount.com"
  ]
}
