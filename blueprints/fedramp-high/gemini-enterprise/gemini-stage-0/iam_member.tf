resource "google_service_account_iam_member" "workspace_manager_token_creator" {
  service_account_id = "projects/${var.main_project_id}/serviceAccounts/workspace-group-manager@${var.main_project_id}.iam.gserviceaccount.com"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.admin_user_email
}
