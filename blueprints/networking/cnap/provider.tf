terraform {
  required_version = ">=1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.33.0"
    }
    google-beta = {
      version = ">= 5.24.0, < 6.0.0"
    }
  }
}

provider "google" {
  project               = var.landing_project_id
  region                = var.region
  billing_project       = var.project
  user_project_override = true
}

provider "google-beta" {
  project               = var.landing_project_id
  region                = var.region
  billing_project       = var.project
  user_project_override = true
}
