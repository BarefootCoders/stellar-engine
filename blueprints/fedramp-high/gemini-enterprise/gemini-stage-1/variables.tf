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

variable "domain" {
  description = "FQDN for the load-balancer hosted apps, where the subdomain will be prepended to."
  type        = string
}

variable "ids_private_ip_prefix_length" {
  description = "The length of the IDS Private IP Prefix."
  type        = number
  default     = 24
}

variable "main_project_id" {
  description = "The GCP Project name."
  type        = string
}

variable "network_name" {
  description = "VPC name in your project"
  type        = string
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

variable "gcs_label_environment" {
  description = "Environment label for the GCS bucket."
  type        = string
  default     = "prod"
}

variable "gemini_enterprise_domain" {
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

# Variable for the customer-provided SSL certificate name
variable "ssl_certificate_name" {
  description = "The name of the pre-uploaded SSL certificate in Google Cloud."
  type        = string
}

variable "gemini_config_id" {
  description = "ID for your Gemini Enterprise instance after running Gem4Gov CLI"
  type        = string
}

variable "admin_group" {
  description = "The email address of the admin user group for Gemini Enterprise."
  type        = string
}

variable "user_group" {
  description = "The email address of the AgentSpace users group."
  type        = string
}

