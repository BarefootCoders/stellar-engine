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
  description = "This is the ID of project."
  type        = string
}

variable "location" {
  type    = string
  default = "us-east4"
}

variable "zone" {
  description = "This is the zone of the instance."
  type        = string
}

variable "allowed_firewall_ports" {
  description = "The allowed ports for the firewall"
  type        = list(string)
}

variable "my_vpc" {
  type = string
}

variable "my_subnet" {
  type = string
}

variable "email" {
  type = string
}

variable "group_email" {
  type = list(string)
}

variable "instance_type" {
  type    = string
  default = "e2-small"
}

variable "instance_name" {
  description = "This is the instance name."
  type        = string
}

variable "ip_cidr_range" {
  type = string
}

variable "image" {
  type = string
}

variable "disk_name" {
  description = "This is the disk name."
  type        = string
}

variable "kms_key_self_link" {
  description = "This is the self link of the KMS key for disk encryption."
  type        = string
}

variable "compute_service_account_id" {
  type = string
}

variable "allowed_source_ranges" {
  description = "These are the allowed source ranges."
  type        = list(string)
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
      protection_level = optional(string, "hsm")
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



