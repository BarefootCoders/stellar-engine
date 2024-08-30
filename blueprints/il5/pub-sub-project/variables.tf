/**
 * Copyright 2024 Google LLC
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

variable "allowed_persistence_regions" {
  description = "The allowed persistence regions for the Pub/Sub topic."
  type        = list(string)
  default     = ["us-east4"]
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
    location                      = optional(string, "us-east4")
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

  default = {
    "default" = {
      destroy_scheduled_duration    = null
      rotation_period               = null
      labels                        = null
      purpose                       = "ENCRYPT_DECRYPT"
      skip_initial_version_creation = false
      version_template = {
        algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
        protection_level = "HSM"
      }

      iam                   = {}
      iam_bindings          = {}
      iam_bindings_additive = {}
    }
  }

  nullable = false
}

variable "project" {
  description = "GCP Project to deploy into."
  type        = string
}

variable "project_id" {
  description = "Project ID."
  type        = string
}

variable "publisher_account_id" {
  description = "Publisher account ID."
  type        = string
}

variable "publisher_name" {
  description = "Publisher name."
  type        = string
}

variable "pubsub_topic" {
  description = "PubSub topic."
  type        = string
}

variable "region" {
  description = "GCP Region to deploy into."
  type        = string
}

variable "subscriber_account_id" {
  description = "Subscriber account ID."
  type        = string
}

variable "subscriber_name" {
  description = "Subscriber name."
  type        = string
}
