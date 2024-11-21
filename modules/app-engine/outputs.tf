output "app_id" {
  value       = google_app_engine_application.app.app_id
  description = "Identifier of the app."
}

output "code_bucket" {
  value       = google_app_engine_application.app.code_bucket
  description = "GCS bucket where the app code is stored."
}

output "default_bucket" {
  value       = google_app_engine_application.app.default_bucket
  description = "GCS bucket where the app content is stored."
}

output "default_hostname" {
  value       = google_app_engine_application.app.default_hostname
  description = "Default hostname for the app."
}

output "gcr_domain" {
  value       = google_app_engine_application.app.gcr_domain
  description = "GCR domain used for storing managed Docker images."
}

output "iap_config" {
  value       = google_app_engine_application.app.iap
  description = "IAP configuration."
}

output "id" {
  description = "An identifier for the resource."
  value       = google_app_engine_application.app.id
}

output "name" {
  value       = google_app_engine_application.app.name
  description = "Unique name of the app."
}

output "url_dispatch_rules" {
  value       = google_app_engine_application.app.url_dispatch_rule
  description = "List of dispatch rule blocks."
}
