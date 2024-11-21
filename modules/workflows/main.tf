# Enable the API service
resource "google_project_service" "workflows" {
  for_each = toset([
    "workflows.googleapis.com",
  ])
  service            = each.key
  disable_on_destroy = false
}

data "google_project" "project" {
  project_id = var.project
}

resource "google_service_account" "default" {
  account_id   = "workflows-sa"
  display_name = "Workflows Service Account."
}

resource "google_project_iam_member" "default" {
  for_each = toset([
    "roles/workflows.invoker",
    "roles/logging.logWriter",
    "roles/serviceusage.serviceUsageConsumer",
  ])
  project    = var.project
  role       = each.key
  member     = "serviceAccount:${google_service_account.default.email}"
  depends_on = [google_service_account.default]
}

resource "google_project_iam_member" "roles" {
  for_each   = toset(var.roles)
  project    = var.project
  role       = each.key
  member     = "serviceAccount:${google_service_account.default.email}"
  depends_on = [google_service_account.default]
}

resource "google_kms_crypto_key_iam_member" "workflows_key_user" {
  crypto_key_id = var.key
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-workflows.iam.gserviceaccount.com"
}

resource "google_workflows_workflow" "default" {
  depends_on = [
    google_service_account.default,
    google_project_iam_member.default,
    google_project_iam_member.roles,
    google_kms_crypto_key_iam_member.workflows_key_user,
  ]
  name                = var.name
  region              = var.region
  description         = var.description
  service_account     = google_service_account.default.id
  call_log_level      = var.logging_level
  //deletion_protection = false
  user_env_vars       = var.env_vars
  crypto_key_name     = var.key

  source_contents = file(var.file)
}