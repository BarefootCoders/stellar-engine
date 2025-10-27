# -----------------------------------------------------------------------------
# IAM ROLE ASSIGNMENTS
# -----------------------------------------------------------------------------
# --- Admin Group Roles ---
# Using google_project_iam_member to additively assign each role.
# This prevents conflicts with other IAM policies.

resource "google_project_iam_member" "admins_discoveryengine_admin" {
  project = var.main_project_id
  role    = "roles/discoveryengine.admin"
  member  = "group:${googleworkspace_group.admins.email}"
}

resource "google_project_iam_member" "admins_aiplatform_admin" {
  project = var.main_project_id
  role    = "roles/aiplatform.admin"
  member  = "group:${googleworkspace_group.admins.email}"
}

resource "google_project_iam_member" "admins_serviceusage_consumer" {
  project = var.main_project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "group:${googleworkspace_group.admins.email}"
}

resource "google_project_iam_member" "admins_logging_viewer" {
  project = var.main_project_id
  role    = "roles/logging.viewer"
  member  = "group:${googleworkspace_group.admins.email}"
}


# --- User Group Roles ---
resource "google_project_iam_member" "users_discoveryengine_user" {
  project = var.main_project_id
  role    = "roles/discoveryengine.user"
  member  = "group:${googleworkspace_group.users.email}"
}

resource "google_project_iam_member" "users_serviceusage_consumer" {
  project = var.main_project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "group:${googleworkspace_group.users.email}"
}