variable "deletion_protection" {
  description = "Deletion proteciton."
  type        = bool
  default     = true
}

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

variable "iam" {
  description = "Keyring IAM bindings in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
  nullable    = false
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

variable "service_account" {
  description = "Service account for Workflows."
  type        = string
}

# In ../../../modules/workflows/variables.tf

variable "kms_key_self_link" {
  description = "The full self-link (projects/../locations/../keyRings/../cryptoKeys/..) of the existing KMS key to use for Workflow encryption (CMEK)."
  type        = string
}
