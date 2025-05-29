terraform {
  required_version = ">= 1.7.4"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 3.53, < 6"
    }
    null = {
      source = "hashicorp/null"
    }
  }
}

provider "google" {
  project = var.main_project_id
  region  = var.region
}