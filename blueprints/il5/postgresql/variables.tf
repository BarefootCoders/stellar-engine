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
  description = "This is the project ID. Please set using a terraform.tfvars file."
  type        = string
}

variable "firewall_name" {
  description = "Firewall name."
  type        = string
}
variable "firewall_source_range" {
  description = "Firewall source IP range."
  type        = list(any)
}

variable "region" {
  description = "This is the region that we are going to be running the cloud sql instance from. "
  type        = string
  default     = "us-east4"
}

variable "database_version" {
  description = "This is the database type that we are running the cloud sql instance."
  type        = string
  default     = "POSTGRES_13"
}

variable "deletion_protection" {
  description = "Terraform deletion protection."
  type        = bool
  default     = true
}

variable "database_instance_tier" {
  description = "This specifies the kind of machine-type that we will be running it from."
  type        = string
  default     = "db-g1-small"
}

variable "database_name" {
  description = "This is the name of the database."
  type        = string
}

variable "network_name" {
  description = "This is the name of the network."
  type        = string
}

variable "allowed_firewall_ports" {
  description = "Allowed firewall ports. Postgresql used 5432."
  type        = list(number)
  default     = [5432]
}

variable "google_compute_global_address_name" {
  description = "Global address for VPC name"
  type        = string
  default     = "postgres"
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

variable "log_error_verbosity" {
  description = "The log_error_verbosity flag controls the verbosity/details of messages logged."
  type        = string
  default     = "default" # Required for CIS Compliance Benchmark 6.2

  validation {
    condition     = contains(["default", "verbose"], var.log_error_verbosity)
    error_message = "Only values \"default\" and \"verbose\" allowed."
  }
}

variable "log_connections" {
  description = "Enabling the log_connections setting causes each attempted connection to the server to be logged, along with successful completion of client authentication."
  type        = string
  default     = "on" # Required for CIS Compliance Benchmark 6.2

  validation {
    condition     = contains(["on", "off"], var.log_connections)
    error_message = "Only values \"on\" and \"off\" allowed."
  }
}

variable "log_disconnections" {
  description = "Enabling the log_disconnections setting logs the end of each session, including the session duration."
  type        = string
  default     = "on" # Required for CIS Compliance Benchmark 6.2

  validation {
    condition     = contains(["on", "off"], var.log_disconnections)
    error_message = "Only values \"on\" and \"off\" allowed."
  }
}

variable "log_statement" {
  description = "The value of log_statement flag determines the SQL statements that are logged."
  type        = string
  default     = "ddl" # Required for CIS Compliance Benchmark 6.2

  validation {
    condition     = contains(["none", "ddl", "mod", "all"], var.log_statement)
    error_message = "Only values \"none\", \"ddl\", \"mod\", and \"all\" allowed."
  }
}

variable "log_min_messages" {
  description = "The log_min_messages flag defines the minimum message severity level that is considered as an error statement."
  type        = string
  default     = "error" # Required for CIS Compliance Benchmark 6.2

  validation {
    condition     = contains(["warning", "error", "log", "fatal", "panic"], var.log_min_messages)
    error_message = "Only values \"warning\", \"error\", \"log\", \"fatal\", and \"panic\" allowed."
  }
}

variable "log_min_error_statement" {
  description = "The log_min_error_statement flag defines the minimum message severity level that are considered as an error statement."
  type        = string
  default     = "error" # Required for CIS Compliance Benchmark 6.2

  validation {
    condition     = contains(["error", "log", "fatal", "panic"], var.log_min_error_statement)
    error_message = "Only values \"error\", \"log\", \"fatal\", and \"panic\" allowed."
  }
}

variable "log_min_duration_statement" {
  description = "Type the minimum amount of execution time of a statement in milliseconds where the total duration of the statement is logged or \"-1\" to disable."
  type        = number
  default     = "-1" # Required for CIS Compliance Benchmark 6.2

  validation {
    condition     = var.log_min_duration_statement >= "-1" && floor(var.log_min_duration_statement) == var.log_min_duration_statement
    error_message = "Only values \"-1\" or a valid whole number are allowed."
  }
}

variable "enable_pgaudit" {
  description = "This extension provides detailed session and object logging to comply with government, financial & ISO standards and provides auditing capabilities to mitigate threats by monitoring security events on the instance."
  type        = string
  default     = "on" # Required for CIS Compliance Benchmark 6.2

  validation {
    condition     = contains(["on", "off"], var.enable_pgaudit)
    error_message = "Only values \"on\" and \"off\" allowed."
  }
}
