resource "google_workflows_workflow" "workflow" {
  depends_on = [
    google_project_iam_binding.bindings,
  ]
  name                = var.name
  region              = var.region
  description         = var.description
  service_account     = var.service_account
  call_log_level      = var.logging_level
  deletion_protection = var.deletion_protection
  user_env_vars       = var.env_vars
  crypto_key_name = var.kms_key_self_link # Note: the resource argument is 'crypto_key_name', but it takes the self-link

  source_contents = file(var.file)
}
