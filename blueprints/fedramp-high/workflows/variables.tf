variable "deletion_protection" {
  description = "Deletion protection for the workflow."
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
  description = "File path to the instructions for the workflow (e.g., example.yaml)."
  type        = string
  default     = "code/example.yaml"
}

variable "logging_level" {
  description = "Logging level of workflow executions. Options: CALL_LOG_LEVEL_UNSPECIFIED, LOG_ALL_CALLS, LOG_ERRORS_ONLY, LOG_NONE."
  type        = string
  default     = "LOG_ERRORS_ONLY"

  validation {
    # Check if the provided value is one of the allowed options
    condition = contains(["CALL_LOG_LEVEL_UNSPECIFIED", "LOG_ALL_CALLS", "LOG_ERRORS_ONLY", "LOG_NONE"], var.logging_level)
    # Provide a helpful error message if the condition is false
    error_message = "Invalid value for var.logging_level. Must be one of: CALL_LOG_LEVEL_UNSPECIFIED, LOG_ALL_CALLS, LOG_ERRORS_ONLY, LOG_NONE."
  }
}

variable "main_project_id" {
  description = "The Google Cloud Project ID where the Workflows resource will be deployed."
  type        = string
}

variable "name" {
  description = "Name of the workflow."
  type        = string
}

variable "region" {
  description = "The Google Cloud region where the Workflows resource will be deployed and where the KMS key is located (if using CMEK in the same region)."
  type        = string
}

variable "core_project_id" {
  description = "The Google Cloud Project ID where shared core services like KMS keys are located."
  type        = string
}

variable "kms_keyring_name" {
  description = "The name of the existing KMS Key Ring to use for workflow encryption (CMEK)."
  type        = string
}

variable "kms_key_name" {
  description = "The name of the existing KMS Crypto Key to use for workflow encryption (CMEK)."
  type        = string
}

variable "kms_key_location" {
  description = "The location (region) of the existing KMS Key Ring and Crypto Key. Defaults to the workflow region if not set."
  type        = string
  default     = null # Or default to var.region
}

variable "workflow_service_account_id" {
  description = "The ID for the custom service account created for the workflow (e.g., 'my-workflow-sa')."
  type        = string
  default     = "workflows-sa" # Provide a default but allow override
}

