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

variable "billing_account" {
  description = "GCP Billing Account ID"
  type        = string
}

variable "check_interval_sec" {
  type    = number
  default = 5
}

variable "default_backend" {
  description = "The default backend for traffic at the load-balancer. Must match the key of one of the backends in the data/apps.yaml file"
  type        = string
}

variable "dmz_vpc_network" {
  description = "The network where the load balancer will be deployed at"
  type        = string
}

variable "domain" {
  description = "FQDN for the load-balancer hosted apps, where the subdomain will be prepended to"
  type        = string
}

variable "google_compute_instance_template" {
  type    = string
  default = "appserver-template"
}

variable "health_check_port" {
  type    = string
  default = "8080"
}

variable "healthy_threshold" {
  type    = number
  default = 2
}

variable "ids_name" {
  description = "Name of IDS."
  type        = string
}

variable "ids_private_ip_prefix_length" {
  type    = number
  default = 24
}

variable "ids_private_ip_range_name" {
  type    = string
  default = "ids-private-address"
}

variable "initial_delay_sec" {
  type    = number
  default = 300
}

variable "instance_list" {
  description = "Instance list to monitor with Cloud IDS"
  type        = list(string)
  default     = null
}

variable "landing_project_id" {
  type = string
}

variable "landing_vpc_network" {
  type        = string
  description = "Landing network name for IDS"
}

variable "machine_type" {
  type    = string
  default = "e2-medium"
}

variable "named_port" {
  type    = string
  default = "8888"
}

variable "net_project" {
  description = "GCP Project to the VPC belongs to. (Defaults to the variable project if not defined)"
  type        = string
  nullable    = true
  default     = null
}

variable "network" {
  description = "Host network for IDS and GCE instance deployment"
  type        = string
}

variable "network_zone" {
  description = "Network zone for IDS"
  type        = string
  default     = "us-east4-c"
}

variable "oauth_brand_number" {
  description = "External Oauth2 consent screens can only be configured via the interactive console. After configuring it, use `gcloud alpha iap oauth-brands list` to lookup the brand id number"
  type        = number
}

variable "organization" {
  description = "GCP Organization is required for Access Context Manager policies which take affect at the org level"
  type        = number
}

variable "packet_mirroring_policy_name" {
  description = "Name of packet mirror policy"
  type        = string
  default     = "testpolicy"
}

variable "prefix" {
  description = "Prefix for naming resources in this blueprint"
  type        = string
  default     = "cnap"
}

variable "project" {
  type = string
}

variable "region" {
  description = "GCP Region to deploy into"
  type        = string
}

variable "severity" {
  description = "Display name of the service account to create."
  type        = string
  default     = "MEDIUM"
}

variable "source_image" {
  type    = string
  default = "debian-cloud/debian-11"
}

variable "subnet" {
  description = "Subnet for deploying the instances"
  type        = string
  default     = "default-us-east4"
}

variable "subnet_list" {
  description = "Subnet list to monitor with Cloud IDS"
  type        = list(any)
  default     = null
}

variable "tag_list" {
  description = "Tag list to monitor with Cloud IDS"
  type        = list(string)
  default     = null
}

variable "tenant_vpc_network" {
  type        = string
  description = "VPC network name for IDS"
}

variable "timeout_sec" {
  type    = number
  default = 5
}

variable "unhealthy_threshold" {
  type    = number
  default = 10
}
