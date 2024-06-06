/**
 * Copyright 2022 Google LLC
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

#TODO: tfdoc annotations

variable "billing_account" {
  # tfdoc:variable:source 0-bootstrap
  description = "Billing account id. If billing account is not part of the same org set `is_org_level` to false."
  type = object({
    id           = string
    is_org_level = optional(bool, true)
  })
  validation {
    condition     = var.billing_account.is_org_level != null
    error_message = "Invalid `null` value for `billing_account.is_org_level`."
  }
}


variable "location" {
  description = "Location of the Compute Engine VM"
  type        = string
  default     = "us-east4"
}


variable "host_project_name" {
  description = "The name of the Host Project"
  type        = string
  default     = "tnbsea-prod-net-spoke-0"
}

variable "peer_network" {
  description = "The Peer Network Project and and global Network Name"
  type        = string
  #Example 
  # default = "projects/tnbsea-prod-net-landing-0/global/networks/prod-landing-0"
  default = "projects/tnbsea-dev-net-spoke-0/global/networks/dev-spoke-0"
  #default = "projects/tnbsea-prod-net-spoke-0/global/networks/prod-spoke-0"
}


variable "peer_network_name" {
  description = "The Peer Network Project and and global Network Name"
  type        = string
  #Example 
  # default = "projects/tnbsea-prod-net-landing-0/global/networks/prod-landing-0"
  default = "prod-spoke-0"
  #default = "projects/tnbsea-prod-net-spoke-0/global/networks/prod-spoke-0"
}




variable "project_id" {
  description = "This is the project ID. Please set using a terraform.tfvars file."
  type        = string
  default     = "tnbsea-dev-tapand-dev"
}

variable "factories_config" {
  description = "Path to folder with YAML resource description data files."
  type = object({
    projects_data_path = string
    budgets = optional(object({
      billing_account       = string
      budgets_data_path     = string
      notification_channels = optional(map(any), {})
    }))
  })
  default = {
    projects_data_path = "data/projects"
  }
  nullable = false
}

variable "prefix" {
  # tfdoc:variable:source 0-bootstrap
  description = "Prefix used for resources that need unique names. Use 9 characters or less."
  type        = string
  validation {
    condition     = try(length(var.prefix), 0) < 10
    error_message = "Use a maximum of 9 characters for prefix."
  }
}

variable "host_project_ids" {
  # tfdoc:variable:source 3-network
  description = "Map of host projects from the networks stages"
  type        = map(string)
  default     = {}
  nullable    = false
}