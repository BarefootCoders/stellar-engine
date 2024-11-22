resource "google_service_account" "workflow_sa" {
  account_id   = "workflows-sa"
  display_name = "Workflows Service Account."
}

# Enable the API service
resource "google_project_service" "workflows" {
  for_each = toset([
    "workflows.googleapis.com",
  ])
  service            = each.key
  disable_on_destroy = false
}

resource "google_project_iam_member" "workflows" {
  for_each = toset([
    "roles/workflows.invoker",
    "roles/logging.logWriter",
    "roles/serviceusage.serviceUsageConsumer",
  ])
  project    = var.project
  role       = each.key
  member     = "serviceAccount:${var.service_account}"
}

resource "google_kms_crypto_key_iam_member" "workflows_key_user" {
  crypto_key_id = var.key
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-workflows.iam.gserviceaccount.com"
}