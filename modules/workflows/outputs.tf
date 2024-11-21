output "service_account" {
  description = "The workflow service account."
  value       = google_service_account.default
}

output "workflow" {
  description = "The newly created workflow."
  value       = google_workflows_workflow.default
}