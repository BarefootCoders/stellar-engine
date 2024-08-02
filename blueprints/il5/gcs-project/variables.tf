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
}

variable "keyring" {
  description = "Keyring attributes."
  type = object({
    location = string
    name     = string
  })
}

variable "public_access_prevention" {
  description = "This provides the ability to toggle Public Access Prevention for the GCS Storage bucket. By settng this variable to enforced, the CIS Benchmark 5.1 compliance control is satsified."
  type        = string
  default     = "enforced"
  validation {
    condition     = contains(["enforced", "inherited"], var.public_access_prevention)
    error_message = "public_access_prevention must be either 'enforced' or 'inherited'."
  }
}

variable "uniform_bucket_level_access" {
  description = "This provides the ability to toggle Uniform Bucket Level Acess for the GCS Storage bucket. By settng this variable to true, the CIS Benchmark 5.2 compliance control is satsified."
  type        = bool
  default     = true
}

variable "prefix" {
  description = "Optional prefix used to generate the bucket name."
  type        = string
  default     = "string"
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty, please use null instead."
  }
}

variable "name" {
  description = "Bucket name suffix."
  type        = string
}

variable "location" {
  description = "Bucket location."
  type        = string
  default     = "us-east4"
}

variable "email" {
  description = "Email address of the user."
  type        = string
}

variable "autoclass" {
  description = "Enable autoclass to automatically transition objects to appropriate storage classes based on their access pattern. If set to true, storage_class must be set to STANDARD. When set to true, All objects added to the bucket begin in Standard storage, even if a different storage class is specified in the request."
  type        = bool
  default     = true
}

variable "storage_class" {
  description = "Bucket storage class."
  type        = string
  default     = "STANDARD"
  validation {
    condition     = contains(["STANDARD", "MULTI_REGIONAL", "REGIONAL", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "Storage class must be one of STANDARD, MULTI_REGIONAL, REGIONAL, NEARLINE, COLDLINE, ARCHIVE."
  }
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