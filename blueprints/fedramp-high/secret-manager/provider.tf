terraform {
  required_version = ">= 1.7.4"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.24.0, < 6.0.0" # tftest
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.24.0, < 6.0.0" # tftest
    }
  }
}

provider "google" {
  project   = var.project_id
  region    = var.region
  zone      = var.zone
}

provider "google-beta" {
  project   = var.project_id
  region    = var.region
  zone      = var.zone
}