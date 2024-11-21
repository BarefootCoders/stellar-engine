# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/app_engine_application
resource "google_app_engine_application" "app" {
  project     = var.project
  location_id = var.location_id

  auth_domain    = var.auth_domain
  database_type  = var.database_type
  serving_status = var.serving_status

  iap {
    oauth2_client_id     = var.iap.oauth2_client_id
    oauth2_client_secret = var.iap.oauth2_client_secret
  }

  feature_settings {
    split_health_checks = var.feature_settings.split_health_checks
  }
}
