variable "project_id" {
  description = "The ID of the project in which to create the GKE cluster."
  type        = string
  default     = "tnbsea-dev-tapand-dev"
}

variable "email" {
  description = "Email address of the user."
  type        = string
  default     = "admin.tapan@dino-runner.darkwolfsolutions.com"
}

variable "group_email" {
  description = "Email address of the group."
  type        = string
  default     = "gcp-devops@dino-runner.darkwolfsolutions.com"
}

variable "region" {
  description = "The GCP region to use for the resources."
  type        = string
  default     = "us-east4"
}
variable "node_config" {
  description = "Node-level configuration."
  type = object({
    boot_disk_kms_key = optional(string)
    service_account   = optional(string)
    tags              = optional(list(string))
  })
  default = {
    # boot_disk_kms_key = "gke-keyringv1"
    boot_disk_kms_key = "projects/tnbsea-dev-tapand-dev/locations/us-east4/keyRings/gke-keyringv1/cryptoKeys/gke-keyname"


  }
}

variable "keyring" {
  description = "Keyring attributes."
  type = object({
    location = string
    name     = string
  })
  default = {
    location = "us-east4"
    name     = "gke-keyringv1"
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
    "gke-keyname" = {
      rotation_period            = "7776000s"
      destroy_scheduled_duration = "2592000s"
      labels = {
        team = "gke-team"
      }
      version_template = {
        algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
        protection_level = "SOFTWARE"
      }
      iam = {
        "roles/cloudkms.cryptoKeyEncrypterDecrypter" = ["user:admin.tapan@dino-runner.darkwolfsolutions.com", "group:gcp-devops@dino-runner.darkwolfsolutions.com"]
      }
      lifecycle = {
        prevent_destroy = true
      }
    }
  }
  nullable = false
}
