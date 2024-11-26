resource "google_workflows_workflow" "workflow" {
  depends_on = [
    google_project_iam_binding.bindings,
  ]
  name            = var.name
  region          = var.region
  description     = var.description
  service_account = var.service_account
  call_log_level  = var.logging_level
  # deletion_protection = false # Not recommended for production environment
  user_env_vars = var.env_vars
  # crypto_key_name     = var.key # Not currently supported via terraform

  source_contents = file(var.file)
}