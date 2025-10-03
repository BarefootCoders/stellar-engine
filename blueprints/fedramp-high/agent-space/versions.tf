terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
    google-workspace = {
      source  = "hashicorp/google-workspace"
      version = ">= 0.8"
    }
  }
}
