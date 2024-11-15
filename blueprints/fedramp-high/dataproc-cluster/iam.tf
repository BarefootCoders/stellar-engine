resource "google_project_iam_member" "worker" {
  project = var.project_id
  role    = "roles/dataproc.worker"
  member  = google_service_account.dataproc_vm.member
}

resource "google_project_iam_member" "dataproc_service_agent" {
  project = var.project_id
  role    = "roles/dataproc.serviceAgent"
  member  = "serviceAccount:service-${data.google_project.current.number}@dataproc-accounts.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "dataproc_network_user" {
  project = var.landing_project_id
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:service-${data.google_project.current.number}@dataproc-accounts.iam.gserviceaccount.com"
}

# Required for delete
resource "google_project_iam_member" "dataproc_compute_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:service-${data.google_project.current.number}@dataproc-accounts.iam.gserviceaccount.com"
}

resource "google_kms_crypto_key_iam_binding" "dataproc_kms" {
  crypto_key_id = "projects/${var.iac_project_id}/locations/${var.region}/keyRings/${var.keyring}/cryptoKeys/${var.key}"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members = [
    google_service_account.dataproc_vm.member,
    "serviceAccount:service-${data.google_project.current.number}@gs-project-accounts.iam.gserviceaccount.com",
    "serviceAccount:service-${data.google_project.current.number}@dataproc-accounts.iam.gserviceaccount.com",
    "serviceAccount:service-${data.google_project.current.number}@compute-system.iam.gserviceaccount.com"
  ]
}