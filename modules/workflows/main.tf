resource "google_project_iam_member" "roles" {
  for_each   = toset(var.roles)
  project    = var.project
  role       = each.key
  member     = "serviceAccount:${var.service_account}"
}

resource "google_workflows_workflow" "default" {
  depends_on = [
    google_project_iam_member.required,
    google_project_iam_member.optional,
  ]
  name                = var.name
  region              = var.region
  description         = var.description
  service_account     = var.service_account
  call_log_level      = var.logging_level
  deletion_protection = false
  user_env_vars       = var.env_vars
  crypto_key_name     = var.key

  source_contents = file(var.file)
}