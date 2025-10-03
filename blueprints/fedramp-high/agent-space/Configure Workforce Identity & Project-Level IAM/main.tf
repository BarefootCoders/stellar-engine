# -----------------------------------------------------------------------------
# GOOGLE WORKSPACE GROUP CREATION
# -----------------------------------------------------------------------------
# Creates the administrators group in your Google Workspace.
resource "google_workspace_group" "admins" {
  email       = "gcp-agentspace-admins@${var.domain}"
  name        = "GCP AgentSpace Admins"
  description = "Administrators for the AgentSpace GCP project."
}

# Creates the users group in your Google Workspace.
resource "google_workspace_group" "users" {
  email       = "gcp-agentspace-users@${var.domain}"
  name        = "GCP AgentSpace Users"
  description = "Users for the AgentSpace GCP project."
}


# -----------------------------------------------------------------------------
# IAM ROLE ASSIGNMENTS
# -----------------------------------------------------------------------------
# --- Admin Group Roles ---
# Using google_project_iam_member to additively assign each role.
# This prevents conflicts with other IAM policies.

resource "google_project_iam_member" "admins_discoveryengine_admin" {
  project = var.project_id
  role    = "roles/discoveryengine.admin"
  member  = "group:${google_workspace_group.admins.email}"
}

resource "google_project_iam_member" "admins_aiplatform_admin" {
  project = var.project_id
  role    = "roles/aiplatform.admin"
  member  = "group:${google_workspace_group.admins.email}"
}

resource "google_project_iam_member" "admins_serviceusage_consumer" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "group:${google_workspace_group.admins.email}"
}

resource "google_project_iam_member" "admins_logging_viewer" {
  project = var.project_id
  role    = "roles/logging.viewer"
  member  = "group:${google_workspace_group.admins.email}"
}


# --- User Group Roles ---
resource "google_project_iam_member" "users_discoveryengine_user" {
  project = var.project_id
  role    = "roles/discoveryengine.user"
  member  = "group:${google_workspace_group.users.email}"
}

resource "google_project_iam_member" "users_serviceusage_consumer" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "group:${google_workspace_group.users.email}"
}
