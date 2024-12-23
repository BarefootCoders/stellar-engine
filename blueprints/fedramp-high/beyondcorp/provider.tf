terraform {
  required_version = ">= 1.7.4"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.1.0, < 7.0.0" # tftest
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 6.1.0, < 7.0.0" # tftest
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.6"
    }
  }
}

provider "google" {
  region                = var.region
  billing_project       = var.project_id
  user_project_override = true
}

provider "google-beta" {
  region                = var.region
  billing_project       = var.project_id
  user_project_override = true
}