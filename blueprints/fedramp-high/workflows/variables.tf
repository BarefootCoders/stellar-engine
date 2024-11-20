variable "description"{
    description = "Description of the workflow."
    type = string
    default = null
}

variable "key" {
  description = "The CMEK used to encrypt the workflow."
  type        = string
}

variable "logging_level" {
    description = "Logging level of workflow executions."
    type = string
    default = "LOG_ERRORS_ONLY"
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