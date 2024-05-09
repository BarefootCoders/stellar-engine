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
  type    = string
}
variable "region" {
  default = "us-east4"
  type    = string
}
variable "dataset_id" {
  default = "dataset_01"
  type    = string
}
variable "dataset_name" {
  default = "named_bq_dataset"
  type    = string
}
#CFF module utilization
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
      protection_level = optional(string, "SOFTWARE")
    }))
  }))
}
variable "bigquery_access" {
  type = list(object({
    role          = string
    user_by_email = string
  }))
  default = []
}
variable "delete_contents_on_destroy" {
  description = "This will delete dataset contents after destroying resource."
  type        = bool
  default     = false
}