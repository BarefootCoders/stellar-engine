data "google_project" "project" {
  project_id = var.project_id
}

resource "google_project_service" "cloud_run" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "binary_authorization" {
  service            = "binaryauthorization.googleapis.com"
  disable_on_destroy = false
}

resource "google_service_account" "cloud_run_service_account" {
  account_id   = "${var.name}-cloud-run-sa"
  display_name = "Cloud Run Service Account for ${var.name}"
}

resource "google_project_iam_member" "cloud_run_permissions" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.cloud_run_service_account.email}"
}

resource "google_kms_crypto_key_iam_member" "cloud_run_service_agent_kms_permissions" {
  crypto_key_id = var.kms_key
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project.number}@serverless-robot-prod.iam.gserviceaccount.com"
}

module "cloud_run" {
  source         = "../../../modules/cloud-run-v2/"
  project_id     = data.google_project.project.project_id
  name           = var.name
  region         = var.region
  encryption_key = var.kms_key
  create_job     = var.is_job
  ingress        = var.ingress
  containers = {
    (var.name) = {
      image = var.container_image
      env   = var.env_vars
      ports = {
        port = {
          container_port = var.port
        }
      }
      resources = {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
        cpu_idle = var.cpu_idle
      }
    }
  }
  service_account     = google_service_account.cloud_run_service_account.email
  deletion_protection = false
}
