terraform {
  required_version = ">= 1.7.4"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.21.0, < 7.0.0" # tftest
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 6.21.0, < 7.0.0" # tftest
    }
    google-workspace = {
      source  = "hashicorp/google-workspace"
      version = ">= 0.8"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.6"
    }
  }
}


provider "google" {
  project               = var.main_project_id
  region                = var.region
  billing_project       = var.main_project_id
  user_project_override = true
}

provider "google-beta" {
  project               = var.main_project_id
  region                = var.region
  billing_project       = var.main_project_id
  user_project_override = true
}

provider "googleworkspace" {
  customer_id = var.google_workspace_customer_id
  impersonated_user_email = "workspace-group-manager@apr24-test-test1-main-0.iam.gserviceaccount.com"
  oauth_scopes = [
    "https://www.googleapis.com/auth/admin.directory.group",
  ]
}
