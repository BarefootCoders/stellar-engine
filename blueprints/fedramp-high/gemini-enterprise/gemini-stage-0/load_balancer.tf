# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Define the Backend Service on the Load Balancer and integrate all components.
resource "google_compute_region_backend_service" "gemini_enterprise_backend" {
  name                  = "gemini-enterprise-backend-service"
  project               = var.main_project_id
  protocol              = "HTTPS"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  region                = var.region


  # Attach the Internet NEG
  backend {
    group           = google_compute_region_network_endpoint_group.gemini_enterprise_neg.id
    capacity_scaler = 1.0s
  }

  # Enable IAP
  iap {
    enabled = true
  }

  log_config {
    enable = true
    sample_rate = 1
  }
}

# 3. Grant a user or group access through IAP.
resource "google_iap_web_backend_service_iam_member" "iap_admin" {
  project             = var.main_project_id
  web_backend_service = "projects/${data.google_project.project.number}/iap_web/compute-${var.region}/services/${google_compute_region_backend_service.gemini_enterprise_backend.name}"
  role                = "roles/iap.httpsResourceAccessor"
  member              = "group:${var.admin_group_email}"
  condition {
    title       = "Admin Access"
    description = "Access for Admins with Strict Device Policy"
    expression  = "request.matchAccessLevels("${var.access_policy_number}", ["strict_device"])"
  }
}

resource "google_iap_web_backend_service_iam_member" "iap_user" {
  project             = var.main_project_id
  web_backend_service = "projects/${data.google_project.project.number}/iap_web/compute-${var.region}/services/${google_compute_region_backend_service.gemini_enterprise_backend.name}"
  role                = "roles/iap.httpsResourceAccessor"
  member              = "group:${var.user_group_email}"
  condition {
    title       = "User Access"
    description = "Access for Users with Moderate Device Policy"
    expression  = "request.matchAccessLevels("${var.access_policy_number}", ["moderate_device"])"
  }
}


# This is an optional but recommended companion to the HTTPS setup,
# creating an HTTP load balancer to redirect HTTP traffic to HTTPS.
resource "google_compute_region_url_map" "gemini_enterprise_http_redirect_url_map" {
  project     = var.main_project_id
  name        = "${var.prefix}-http-redirect-url-map"
  region      = var.region
  description = "URL map to redirect HTTP to HTTPS"

  default_url_redirect {
    https_redirect         = true
    strip_query            = false
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
  }
}

resource "google_compute_region_target_http_proxy" "gemini_enterprise_http_proxy" {
  project    = var.main_project_id
  name       = "${var.prefix}-http-proxy"
  region     = var.region
  url_map    = google_compute_region_url_map.gemini_enterprise_http_redirect_url_map.id
}

resource "google_compute_forwarding_rule" "gemini_enterprise_forwarding_rule" {
  project               = var.main_project_id
  name                  = "${var.prefix}-http-forwarding-rule"
  region                = var.region
  ip_protocol           = "TCP"
  port_range            = "80" # HTTP port
  load_balancing_scheme = "EXTERNAL_MANAGED" # Changed to EXTERNAL_MANAGED
  network               = data.google_compute_network.gemini_enterprise_vpc.self_link
  ip_address            = google_compute_address.gemini_enterprise_ip.address
  target                = google_compute_region_target_http_proxy.gemini_enterprise_http_proxy.id
}