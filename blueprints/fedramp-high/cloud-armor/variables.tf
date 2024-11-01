variable "project_id" {
  description = "The ID for the project that the Cloud Armor policies will be used in."
  type        = string
}

variable "region" {
  description = "The Google Cloud region."
  type        = string
  default     = "us-east4"
}

variable "rules_file" {
  description = "Path to the YAML file containing the rules."
  type        = string
  default     = "rules.yaml"
}