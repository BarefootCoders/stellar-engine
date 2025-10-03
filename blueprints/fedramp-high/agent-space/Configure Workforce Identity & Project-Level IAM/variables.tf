variable "project_id" {
  type        = string
  description = "The Google Cloud project ID to apply IAM roles to."
  # Example: "agentspace-prod-12345"
}

variable "domain" {
  type        = string
  description = "The Google Workspace domain name for creating groups."
  # Example: "yourcompany.com"
}
