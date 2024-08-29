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

variable "allowed_firewall_ports" {
  description = "The list of the Allowed Ports."
  type        = list(any)
  #Example default     = ["22", "443"]
}

variable "auto_delete" {
  description = "Persistent Disk auto delete options."
  type        = bool
  # Example default = true
}

variable "compute_service_account_id" {
  description = "The Service Account for Compute Engine."
  type        = string
  # Example default = "computeblue"
}

variable "email" {
  description = "Email address of the user."
  type        = string
  # Example default = "admin.user-anme@example.google.com"
}

variable "instance_name" {
  description = "Provide the name of the Compute Instance."
  type        = string
  #Example default     = "Compute-Instance-Name-1"
}

variable "instance_type" {
  description = "The Machine Type for the Compute Engine VM."
  type        = string
  default     = "e2-micro"
  #Example  default     = "e2-micro"
}

variable "ip_cidr_range" {
  description = "The IP CIDR range for the VPC."
  type        = string
  #Example default = "10.0.1.0/24"
}

variable "keyring" {
  description = "Keyring attributes."
  type = object({
    location = string
    name     = string
  })
  # Example
  # default = {
  #  location = "us-east4"
  #  name     = "name-of-keyring"
  # }
  # The name of the Key Ring, and location. The Location for IL5 can be us-east4 or us-central1
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

variable "location" {
  description = "Location of the Compute Engine VM."
  type        = string
  default     = "us-east4"

}

variable "project" {
  description = "GCP Project to deploy into."
  type        = string
}

variable "project_id" {
  description = "Project ID."
  type        = string
  # Example default = "project-id-here"
}

variable "region" {
  description = "GCP Region to deploy into."
  type        = string
}

variable "source_ranges_allowed" {
  description = "The List of the source IP CIDR range allowed to connect to the Compute Engine VM."
  type        = list(any)
  #Example default = ["10.0.1.0/24"]
}

variable "zone" {
  description = "Zone of the Compute Engine VM us-east4-c , us-east4-a, us-east4-b."
  type        = string
  default     = "us-east4-c"
}
