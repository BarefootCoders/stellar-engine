data "google_project" "project" {}

# Enable the API
resource "google_project_service" "workflows" {
  for_each = toset([
    "workflows.googleapis.com",
  ])
  service            = each.key
  disable_on_destroy = false
}

resource "google_service_account" "workflow_sa" {
  account_id   = "workflows-sa"
  display_name = "Workflows Service Account."
}

# Provide time for Workflows Service Agent to be created
resource "time_sleep" "wait_30_seconds" {
  depends_on      = [google_service_account.workflow_sa]
  create_duration = "30s"
}

module "workflows" {
  source          = "../../../modules/workflows"
  project         = var.project
  name            = var.name
  region          = var.region
  description     = var.description
  logging_level   = var.logging_level
  env_vars        = var.env_vars
  file            = var.file
  service_account = google_service_account.workflow_sa.email

  iam = {
    "roles/workflows.invoker"                 = [google_service_account.workflow_sa.member],
    "roles/logging.logWriter"                 = [google_service_account.workflow_sa.member],
    "roles/serviceusage.serviceUsageConsumer" = [google_service_account.workflow_sa.member],
  }
  depends_on = [
    google_project_service.workflows,
    google_service_account.workflow_sa.
    time_sleep.wait_30_seconds
  ]
}