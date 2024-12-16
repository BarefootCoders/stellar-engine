variable "kms_key" {
  description = "Full path to KMS key for pubsub."
  type        = string
  default     = null
}

variable "landing_project_id" {
  description = "Landing project id."
  type        = string
}

variable "name" {
  description = "Name of DataFusion instance."
  type        = string
}

variable "network" {
  description = "Full path to VPC."
  type        = string
}

variable "project_id" {
  description = "Project id."
  type        = string
}

variable "region" {
  description = "Location to deploy job."
  type        = string
}

variable "subnet" {
  description = "Full path to subnet."
  type        = string
}