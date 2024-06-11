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
variable "project_id" {
  description = "Project ID"
  type        = string
  #default     = "project-id"
}

variable "email" {
  description = "Email address of the user."
  type        = string
  # Example  default = "your-email-address@your-domain.com"
}

variable "location" {
  description = "Location of the Shielded Compute VM"
  type        = string
  default     = "us-east4"
}

variable "host_project_name" {
  description = "The name of the Host Project"
  type        = string
  #Example   default     = "abc-host-project-name"
}

variable "peer_network_name" {
  description = "The Peer Network Project and and global Network Name"
  type        = string
  #Example   default = "peer-network-name"
}

variable "subnets_cidr_a" {
  description = "The Subnet CIDR"
  type        = string
  #Example default ="10.200.12.0/25"
}

variable "subnets_cidr_b" {
  description = "The Subnet CIDR"
  type        = string
  #Example default ="10.200.12.0/25"
}

variable "subnets_cidr_c" {
  description = "The Subnet CIDR"
  type        = string
  #Example default ="10.200.12.0/25"
}