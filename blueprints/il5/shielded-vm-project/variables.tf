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
  # TODO: Update the Project ID , example project-abc-123
}

variable "email" {
  description = "Email address of the user."
  type        = string
  # TODO: Update the email address
  # Example default = "admin.user-anme@example.google.com"

}

variable "keyring" {
  description = "Keyring attributes."
  type = object({
    location = string
    name     = string
  })
  default = {
    location = ""
    name     = ""
    # Example location = "us-east4"
    # Example name     = "name-of-keyring"
    # TODO: Update the name of the Key Ring, and location. The Location for IL5 can be us-east4 or us-central1  
  }
}

variable "location" {
  description = "Location of the Shielded Compute VM"
  type        = string
  default     = "us-east4"
  # TODO: Update the Location of the Compute VM. The Location for IL5 can be us-east4 or us-cental1
}

variable "zone" {
  description = "Zone of the Shielded Compute VM us-east4-c , us-east4-a, us-east4-b"
  type        = string
  default     = "us-east4-c"
  #TODO Update the Zone value to us-east4-c , us-east4-a, us-east4-b
}

variable "instance_name" {
  description = "Provide the name of the Compute Instance"
  type        = string
  #TODO Update the name of the Compute Instance
}

variable "shielded_config" {
  description = "Shielded VM configuration of the instances."
  type = object({
    enable_secure_boot          = bool
    enable_vtpm                 = bool
    enable_integrity_monitoring = bool
  })
  default = {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
}


variable "ip_cidr_range" {
  description = "The IP CIDR range for the VPC"
  type        = string
  default     = "10.0.1.0/24"
  #TODO Update the VPC CIDR IP Range
}

variable "source_ranges_allowed" {
  description = "The List of the source IP CIDR range allowed to connect to the Shieled Compute VM"
  type        = list(any)
  default     = ["10.0.1.0/24"]
  #TODO Update the List of the source IP CIDR range allowed to connect
}


variable "allowd_firewall_ports" {
  description = "The list of the Allowed Ports"
  type        = list(any)
  default     = ["22", "443"]
  #TODO Update the The list of the Allowed Ports
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
        protection_level = "SOFTWARE"
      }

      iam                   = {}
      iam_bindings          = {}
      iam_bindings_additive = {}
    }
  }
  nullable = false
}

 