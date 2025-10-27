variable "main_project_id" {
  description = "The main project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resources like KMS"
  type        = string
}

variable "geolocation" {
  description = "Location for Discovery Engine resources (us, eu, or global)."
  type        = string
  default     = "us"
}