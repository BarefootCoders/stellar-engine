#https://cloud.google.com/spanner/docs/instance-configurations#regional-configurations
variable "config_name" {
  description = "Cloud spanner instance config name."
  type        = string
  default     = "regional-us-east4"
}

variable "database_name" {
  description = "Database name."
  type        = string
}

variable "database_user" {
  description = "Database user or group. Must start with \"user:\" or \"group:\" or \"serviceAccount:\"."
  type        = string
}

variable "display_name" {
  description = "Cloud spanner display name."
  type        = string
}

variable "high_priority_cpu_utilization_percent" {
  description = "High priority cpu utilization percent."
  type        = number
  default     = 75
}

variable "instance_name" {
  description = "Cloud spanner instance name."
  type        = string
}

variable "location_id" {
  description = "Region to create your App Engine resource."
  type        = string
  default     = "us-east4"
}

variable "max_processing_units" {
  description = "Max processing units for autoscaling."
  type        = number
  default     = 3000
}

variable "min_processing_units" {
  description = "Min processing units for autoscaling."
  type        = number
  default     = 2000
}

variable "project" {
  description = "Project to deploy Cloud Spanner instance."
  type        = string
}

variable "storage_utilization_percent" {
  description = "Storage utilization percent."
  type        = number
  default     = 90
}