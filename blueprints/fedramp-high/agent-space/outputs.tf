output "admin_group_email" {
  value       = google_workspace_group.admins.email
  description = "The email address of the AgentSpace administrators group."
}

output "user_group_email" {
  value       = google_workspace_group.users.email
  description = "The email address of the AgentSpace users group."
}
