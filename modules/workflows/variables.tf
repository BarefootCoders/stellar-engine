variable "description" {
  description = "Description of the workflow."
  type        = string
  default     = null
}

variable "env_vars" {
  description = "Environment variables made available to your workflow execution."
  type        = map(string)
  default     = null
}

variable "file" {
  description = "File path to the instructions for the workflow."
  type        = string
}

variable "key" {
  description = "The CMEK used to encrypt the workflow."
  type        = string
}

variable "logging_level" {
  description = "Logging level of workflow executions."
  type        = string
  default     = "LOG_ERRORS_ONLY"
}

variable "name" {
  description = "Name of the workflow."
  type        = string
}

variable "project" {
  description = "The Google Project ID."
  type        = string
}

variable "region" {
  description = "The Google Cloud region."
  type        = string
}

variable "roles" {
  description = "Additional roles to grant to the workflows service account."
  type        = list(string)
  default     = ["roles/workflows.invoker"]
  nullable    = false
}