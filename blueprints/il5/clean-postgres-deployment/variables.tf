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
  description = "This is the project ID. Please set using a terraform.tfvars file."
  type        = string
}

variable "region" {
  description = "This is the region that we are going to be running the cloud sql instance from. "
  type        = string
  default     = "us-east4"
}

variable "database_version" {
  description = "This is the database type that we are running the cloud sql instance."
  type        = string
  default     = "POSTGRES_14"
}

variable "database_instance_tier" {
  description = "This specifies the kind of machine-type that we will be running it from."
  type        = string
  default     = "db-g1-small"
}

variable "database_name" {
  description = "This is the name of the database."
  type        = string
}

variable "network_name" {
  description = "This is the name of the network."
  type        = string
}