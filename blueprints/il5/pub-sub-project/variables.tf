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
variable "project_id" {
  type = string
}

variable "location" {
  type    = string
  default = "us-east4"
}

variable "email" {
  type = string
}

variable "pubsub_subscription_name" {
  type = string
}

variable "pubsub_topic" {
  type = string
}

variable "push_endpoint" {
  type = string
}
variable "publisher_name" {
  type = string
}

variable "subscriber_name" {
  type = string
}

variable "publisher_account_id" {
  type = string

}

variable "subscriber_account_id" {
  type = string

}

variable "keyring" {
  description = "Keyring attributes."
  type = object({
    location = string
    name     = string
  })

}

variable "allowed_persistence_regions" {
  description = "The allowed persistence regions for the Pub/Sub topic"
  type        = list(string)
  default     = ["us-east4"]
}

variable "subscriptions" {
  description = "A map of subscription configurations"
  type = map(object({
    labels                       = map(string)
    ack_deadline_seconds         = number
    message_retention_duration   = string
    retain_acked_messages        = bool
    filter                       = string
    enable_message_ordering      = bool
    enable_exactly_once_delivery = bool
    expiration_policy_ttl        = string
    dead_letter_policy = object({
      topic                 = string
      max_delivery_attempts = number
    })
    retry_policy = object({
      maximum_backoff = string
      minimum_backoff = string
    })
    push = object({
      endpoint   = string
      attributes = map(string)
      oidc_token = object({
        service_account_email = string
        audience              = string
      })
    })
    bigquery = object({
      table               = string
      use_topic_schema    = bool
      write_metadata      = bool
      drop_unknown_fields = bool
    })
    cloud_storage = object({
      bucket          = string
      filename_prefix = string
      filename_suffix = string
      max_duration    = string
      max_bytes       = number
      avro_config = object({
        write_metadata = bool
      })
    })
  }))
  default = {}
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
