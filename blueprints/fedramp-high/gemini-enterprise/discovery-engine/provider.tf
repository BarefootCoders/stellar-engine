provider "google" {
  project = var.main_project_id
  region  = var.region
}

provider "google-beta" {
  project = var.main_project_id
  region  = var.region
  user_project_override = true
  billing_project = var.main_project_id
}

resource "google_project_service" "services" {
  project = var.main_project_id
  for_each = toset([
    "discoveryengine.googleapis.com",
    "cloudkms.googleapis.com",
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    "accesscontextmanager.googleapis.com",
    "beyondcorp.googleapis.com",
    "binaryauthorization.googleapis.com",
    "iam.googleapis.com",
    "iap.googleapis.com",
    "orgpolicy.googleapis.com",
    "serviceusage.googleapis.com"
  ])
  service = each.value
  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_on_destroy = false

}
