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
  project = var.project
  region  = var.region
}

