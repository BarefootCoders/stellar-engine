variable "ids_name" {
  description = "Name for ids."
  type        = string
}

variable "ids_private_ip_prefix_length" {
  description = "The length of the IDS Private IP Prefix."
  type        = number
  default     = 24
}

variable "landing_project_id" {
  description = "The Landing Project ID."
  type        = string
}

variable "network" {
  description = "VPC network."
  type        = string
}

variable "packet_mirroring_policy_name" {
  description = "Name of packet mirror policy."
  type        = string
  default     = "cnap-packet-mirror"
}

variable "prefix" {
  description = "Prefix for naming resources in this blueprint."
  type        = string
  default     = "cnap"
}

variable "project" {
  description = "The GCP Project name."
  type        = string
}

variable "region" {
  description = "GCP Region to deploy into."
  type        = string
}

variable "severity" {
  description = "Impact of an incident on a system."
  type        = string
  default     = "MEDIUM"
}

variable "subnet" {
  description = "Subnet for deploying the instances."
  type        = string
  default     = "default-us-east4"
}

variable "subnet_list" {
  description = "Subnet list to monitor with Cloud IDS."
  type        = list(any)
  default     = null
}