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
  description = "The ID of the project in which to provision resources."
  type        = string
}

variable "location" {
  description = "location of dataset."
  type        = string
}

variable "region" {
  description = "The region in which to provision resources."
  type        = string
  default     = "us-east4"
}

variable "email" {
  description = "The email of the user."
  type        = string
}

variable "network_name" {
  description = "The email of the user."
  type        = string
}

variable "subnet_name" {
  description = "The email of the user."
  type        = string
}

variable "subnet_ip" {
  description = "The email of the user."
  type        = string
}

variable "dataset_id" {
  description = "The dataset of bigquery."
  type        = string
}

variable "pubsub_topic_name" {
  description = "The topic name of pub sub"
  type        = string
}

variable "allowed_persistence_regions" {
  description = "The allowed persistence regions for the Pub/Sub topic"
  type        = list(string)
  default     = ["us-east4"]
}

variable "pubsub_subscription_name" {
  description = "The sunscription name of pub sub"
  type        = string
}

variable "keyring" {
  description = "Keyring attributes."
  type = object({
    location = string
    name     = string
  })
}

variable "keys" {
  description = "Key names and base attributes. Set attributes to null if not needed."
  type = map(object({
    destroy_scheduled_duration    = optional(string)
    rotation_period               = optional(string)
    labels                        = optional(map(string))
    purpose                       = optional(string, "ENCRYPT_DECRYPT")
    skip_initial_version_creation = optional(bool, false)
    version_template = optional(object({
      algorithm        = string
      protection_level = optional(string, "HSM")
    }))

    iam = optional(map(list(string)), {})
    iam_bindings = optional(map(object({
      members = list(string)
      role    = string
      condition = optional(object({
        expression  = string
        title       = string
        description = optional(string)
      }))
    })), {})
    iam_bindings_additive = optional(map(object({
      member = string
      role   = string
      condition = optional(object({
        expression  = string
        title       = string
        description = optional(string)
      }))
    })), {})
  }))
}

variable "bucket_name" {
  description = "This is the name of the bucket."
  type        = string
}

variable "dataflow_service_account_id" {
  description = "This is the name of the dataflow service accoount id."
  type        = string
}

variable "storage_class" {
  description = "This is the storage class of the storage bucket."
  type        = string
}

variable "prefix" {
  description = "This is the prefix for all resources."
  type        = string
}

variable "dataflow_name" {
  description = "This is the name of the dataflow job."
  type        = string
}

variable "zone" {
  description = "This is the name of the zone."
  type        = string
  default     = "us-east4"
}

variable "template_gcs_path" {
  description = "This is the template path of the dataflow job."
  type        = string
}

variable "temp_gcs_location" {
  description = "This is the temporary gcs path."
  type        = string
}

variable "input_topic" {
  description = "This is the value of input topic."
  type        = string
}

variable "output_table" {
  description = "This is the value of input topic."
  type        = string
}

variable "bigquery_table_id" {
  description = "This is the temorary directory of bigQuery."
  type        = string
}
