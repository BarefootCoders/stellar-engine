variable "auth_domain" {
  description = "The domain to authenticate users with when using App Engine's User API."
  type        = string
  default     = null
}

variable "database_type" {
  description = "The type of the Cloud Firestore or Cloud Datastore database associated with this application."
  type        = string
  default     = null
}

variable "feature_settings" {
  description = "A block of optional settings to configure specific App Engine features."
  type = object({
    split_health_checks = optional(bool, true)
  })

  nullable = true
  default  = {}
}

variable "iap" {
  description = "Settings for enabling Cloud Identity Aware Proxy."
  type = object({
    oauth2_client_id     = optional(string, "")
    oauth2_client_secret = optional(string, "")
  })

  nullable = true
  default  = {}
}

variable "location_id" {
  description = "Region to create your App Engine resource."
  type        = string
}

variable "project" {
  description = "Project to create your App Engine resource."
  type        = string
}

variable "serving_status" {
  description = "The serving status of the app."
  type        = string
  default     = null
}
