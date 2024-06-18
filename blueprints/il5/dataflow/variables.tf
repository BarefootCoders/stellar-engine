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

variable "region" {
  description = "The region in which to provision resources."
  type        = string
  default     = "us-east4"
}

variable "name" {
  description = "The name of dataflow instance."
  type        = string
}

variable "email" {
  description = "The email of the user."
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

variable "service_account_email" {
  description = "This is the email of the service account."
  type        = string
}

variable "zone" {
  description = "The zone in which the dataflow job will be deployed."
  type        = string
}

variable "compute_service_account_id" {
  description = "The compute service account id."
  type        = string
}

variable "kms_key_self_link" {
  description = "This is the self link of the KMS key for disk encryption."
  type        = string
}

variable "temp_gcs_location" {
  description = "The location in which the dataflow job will be deployed."
  type        = string
  default     = "us-east4"
}

variable "template_gcs_path" {
  description = "The path in which the dataflow job will be deployed."
  type        = string
  default     = "us-east4"
}

variable "bucket_name" {
  description = "This is the name of the bucket."
  type        = string
}