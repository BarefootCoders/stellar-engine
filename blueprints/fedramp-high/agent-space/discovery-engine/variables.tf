variable "main_project_id" {
  description = "The main project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resources like KMS"
  type        = string
}

variable "geolocation" {
  description = "The multi-region for Discovery Engine (e.g., us, eu, global)"
  type        = string
}
