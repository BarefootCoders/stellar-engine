/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable "access_policy_number" {
  description = "There can only be one Access Policy per GCP Org. Use gcloud access-context-manager policies list --organization <org-number> to list it."
  type        = number
}

variable "default_backend" {
  description = "The default backend for traffic at the load-balancer. Must match the key of one of the backends in the data/apps.yaml file."
  type        = string
}

variable "domain" {
  description = "FQDN for the load-balancer hosted apps, where the subdomain will be prepended to."
  type        = string
}

variable "google_workspace_customer_id" {
  description = "The Google Workspace Customer ID."
  type        = string
}

variable "ids_private_ip_prefix_length" {
  description = "The length of the IDS Private IP Prefix."
  type        = number
  default     = 24
}

variable "machine_type" {
  description = "The type of machine to use."
  type        = string
  default     = "n2d-highcpu-2"
}

variable "main_project_id" {
  description = "The GCP Project name."
  type        = string
}

variable "net_project" {
  description = "GCP Project to the VPC belongs to. (Defaults to the variable project if not defined)."
  type        = string
  nullable    = true
  default     = null
}

variable "network_name" {
  description = "Host network for IDS and GCE instance deployment."
  type        = string
}

variable "network_project_id" {
  description = "The Landing Project ID."
  type        = string
}

variable "oauth_brand_number" {
  description = "External Oauth2 consent screens can only be configured via the interactive console. After configuring it, use `gcloud alpha iap oauth-brands list` to lookup the brand id number."
  type        = number
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

variable "region" {
  description = "GCP Region to deploy into."
  type        = string
}

variable "severity" {
  description = "Display name of the service account to create."
  type        = string
  default     = "MEDIUM"
}

variable "subnetwork_list" {
  description = "Subnet list to monitor with Cloud IDS."
  type        = list(any)
  default     = null
}

variable "subnetwork_name" {
  description = "Subnet for deploying the instances."
  type        = string
}

variable "admin_user_email" {
  description = "The email address of the admin user for IAM bindings."
  type        = string
}

variable "company_name" {
  description = "Company name for Discovery Engine configuration."
  type        = string
  default     = "Department of Technology"
}

variable "gcs_label_environment" {
  description = "Environment label for the GCS bucket."
  type        = string
  default     = "prod"
}

variable "agent_space_gcs_bucket_name" {
  description = "The name of the GCS bucket to be used as the data source for the Discovery Engine Data Connector."
  type        = string
  default     = "your-bucket-name-placeholder"
}

variable "geolocation" {
  description = "Location for Discovery Engine resources (us, eu, or global)."
  type        = string
  default     = "us"
}

variable "admin_group_email" {
  description = "The email address of the AgentSpace administrators group."
  type        = string
}

variable "user_group_email" {
  description = "The email address of the AgentSpace users group."
  type        = string
}

variable "gcs_data_store_names" {
  description = "A list of names to use for creating GCS buckets and associated Discovery Engine Data Stores."
  type        = list(string)
  default     = []
}

variable "bq_data_store_configs" {
  description = "A list of objects defining BigQuery datasets and tables to create and connect to Discovery Engine. Each object should have 'dataset_id' and 'table_id'."
  type        = list(object({
    dataset_id = string
    table_id   = string
  }))
  default     = []
}
