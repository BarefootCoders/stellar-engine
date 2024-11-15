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
variable "cluster_name" {
  description = "Name of the Dataproc cluster."
  type        = string
}

variable "dataproc_bucket_name" {
  description = "Name of the gcs bucket that will be created and used with Dataproc. This must be globally unique."
  type        = string
}

variable "dataproc_name" {
  description = "Name of the Dataproc instance."
  type        = string
}

variable "firewall_name" {
  description = "The Dataproc firewall name."
  type        = string
}

variable "iac_project_id" {
  description = "The ID of the iac project where the KMS key is."
  type        = string
}

variable "key" {
  description = "KMS key name."
  type        = string
}

variable "keyring" {
  description = "KMS keyring name."
  type        = string
}

variable "landing_project_id" {
  description = "The ID of the landing zone project where the VPC is."
  type        = string
}

variable "network_name" {
  description = "The network name."
  type        = string
}

variable "project_id" {
  description = "The ID of the main project."
  type        = string
}

variable "region" {
  description = "The region in which to provision resources."
  type        = string
  default     = "us-east4"
}

variable "subnet_name" {
  description = "The subnet name."
  type        = string
}
