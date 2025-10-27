# -----------------------------------------------------------------------------
# GOOGLE WORKSPACE GROUP CREATION
# -----------------------------------------------------------------------------
# Creates the administrators group in your Google Workspace.
resource "googleworkspace_group" "admins" {
  provider    = googleworkspace
  email       = "gcp-agentspace-admins@${var.domain}"
  name        = "GCP AgentSpace Admins"
  description = "Administrators for the AgentSpace GCP project."
}

# Creates the users group in your Google Workspace.
resource "googleworkspace_group" "users" {
  provider    = googleworkspace
  email       = "gcp-agentspace-users@${var.domain}"
  name        = "GCP AgentSpace Users"
  description = "Users for the AgentSpace GCP project."
}
