data "google_access_context_manager_access_policy" "existing_policy" {
  parent = "organizations/${var.organization_id}"
}

resource "google_project_service" "required_apis" {
  for_each = toset([
    "accesscontextmanager.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iap.googleapis.com",
  ])
  project = var.project_id
  service = each.key

  disable_on_destroy = false
}

# Access Level for Device Endpoint Verification
resource "google_access_context_manager_access_level" "endpoint_verified" {
  parent = "accessPolicies/${data.google_access_context_manager_access_policy.existing_policy.id}"
  title  = var.policy_title
  name   = var.endpoint_name
  basic {
    conditions {
      device_policy {
        allowed_encryption_statuses = ["ENCRYPTION_UNSUPPORTED", "ENCRYPTED"]
        require_screen_lock          = true
      }
    }
  }
}

# IAP Backend Service
resource "google_compute_backend_service" "iap_backend" {
  name        = "iap-backend-service"
  project     = var.project_id
  description = "Backend for IAP-secured resources"

  iap {
    enabled              = true
    oauth2_client_id     = var.oauth_client_id
    oauth2_client_secret = var.oauth_client_secret
    }
  }

# IAM Binding for IAP Secured Resources
resource "google_project_iam_member" "iap_user" {
  project = var.project_id
  role    = "roles/iap.httpsResourceAccessor"
  member  = var.iap_user_email
}