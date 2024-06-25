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
  # Example default = "project-id-here"
}

variable "email" {
  description = "Email address of the user."
  type        = string
  # Example default = "admin.user-anme@example.google.com"
}

variable "compute_service_account_id" {
  description = "The Service Account for Compute Engine. Provide the name to be given to the Computer Engine Service Account."
  type        = string
  # Example default = "computeso"
}

variable "location" {
  description = "Location of the Compute Engine VM"
  type        = string
  default     = "us-east4"
}

variable "zone" {
  description = "Zone of the Compute Engine VM us-east4-c , us-east4-a, us-east4-b"
  type        = string
  # example default     = "us-east4-c"
}

variable "instance_name" {
  description = "The name of the compute engine instance"
  type        = string
  #example default     = "security-onio"
}

variable "instance_type" {
  description = "The Machine Type for the Compute Engine VM"
  type        = string
  #Example  default     = "e2-standard-8"
}

variable "boot_disk_size_gb" {
  description = "The Size of the Boot Disk in GB"
  type        = number
  #Example  default     = 300
}

variable "boot_disk_image" {
  description = "The Name of the Disk Image  for the Compute Engine VM"
  type        = string
  #Example  default     = "centos-stream-9-v20240613"
}

variable "vpc_a_name" {
  description = "The VPC A name"
  type        = string
  #Example default ="vpc-so-a"
}

variable "subnet_a_name" {
  description = "The Subnet A Name"
  type        = string
  #Example default ="subnet-onion-a-vpca"
}

variable "subnet_a_ip_cidr" {
  description = "The Subnet a IP CIDR CIDR"
  type        = string
  #Example default ="10.1.8.0/25"
}

variable "subnet_a_secondary_ip_cidr_1" {
  description = "The Subnet a Seoncary IP CIDR for one"
  type        = string
  #Example default ="10.1.8.128/25"
}

variable "subnet_a_secondary_ip_cidr_2" {
  description = "The Subnet a Seoncary IP CIDR for two"
  type        = string
  #Example default ="10.1.9.0/25"
}

variable "vpc_b_name" {
  description = "The VPC B name"
  type        = string
  #Example default ="vpc-so-b"
}

variable "subnet_b_name" {
  description = "The Subnet B Name"
  type        = string
  #Example default ="subnet-onion-b-vpcb"
}

variable "subnet_b_ip_cidr" {
  description = "The Subnet a IP CIDR CIDR"
  type        = string
  #Example default ="10.1.9.128/25"
}

variable "subnet_b_secondary_ip_cidr_1" {
  description = "The Subnet a Seoncary IP CIDR for one"
  type        = string
  #Example default ="10.1.10.0/25"
}

variable "subnet_b_secondary_ip_cidr_2" {
  description = "The Subnet a Seoncary IP CIDR for two"
  type        = string
  #Example default ="10.1.10.128/25"
}




variable "nat_a_name" {
  description = "The NAT Name a"
  type        = string
  #Example default ="nat-so-a"
}

variable "nat_b_name" {
  description = "The NAT Name b"
  type        = string
  #Example default ="nat-so-b"
}

variable "auto_delete" {
  description = "Persistent Disk auto delete options"
  type        = bool
  #example default = true
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
