terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.40.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.40.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.1"
    }
  }
}
