terraform {
  required_version = ">= 1.7.4"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.21.0, < 7.0.0" # tftest
    }
  }
}


provider "google" {
  project = var.project_id
  region  = var.location
}