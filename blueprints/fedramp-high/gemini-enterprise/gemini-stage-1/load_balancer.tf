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

# Data source to get the details of the customer's pre-uploaded SSL certificate
data "google_compute_region_ssl_certificate" "gemini_enterprise_cert" {
  project = var.main_project_id
  name    = var.ssl_certificate_name
  region  = var.region
}

# Data source to get the backend service created in stage-0
data "google_compute_region_backend_service" "gemini_enterprise_backend" {
  project = var.main_project_id
  name    = "gemini-enterprise-backend-service"
  region  = var.region
}

# Data source to get the network created in stage-0
data "google_compute_network" "gemini_enterprise_vpc" {
  project = var.main_project_id
  name    = "gemini-enterprise-vpc"
}

# Data source to get the IP address created in stage-0
data "google_compute_address" "gemini_enterprise_ip" {
  project = var.main_project_id
  name    = "gemini-enterprise-ip"
  region  = var.region
}

# This resource defines the URL map with the specified routing rules.
resource "google_compute_region_url_map" "gemini_enterprise_load_balancer" {
  project               = var.main_project_id
  name            = "${var.prefix}-gemini-enterprise-url-map"
  region          = var.region
  description     = "URL map for ${var.prefix}-gemini-enterprise"
  default_service = data.google_compute_region_backend_service.gemini_enterprise_backend.id

  host_rule {
    hosts        = ["${var.gemini_enterprise_domain}"]
    path_matcher = "path-matcher-1"
  }

  path_matcher {
    name            = "path-matcher-1"
    default_service = data.google_compute_region_backend_service.gemini_enterprise_backend.id

    route_rules {
      priority = 100
      match_rules {
        prefix_match = "/"
      }
      service = data.google_compute_region_backend_service.gemini_enterprise_backend.id
      route_action {
        url_rewrite {
          host_rewrite        = "vertexaisearch.cloud.google.com"
          path_prefix_rewrite = "${var.gemini_config_id}"
        }
      }
    }
  }
}

# This resource creates the target HTTPS proxy for the load balancer.
# It now references the pre-existing SSL certificate via the data source.
resource "google_compute_region_target_https_proxy" "gemini_enterprise_https_proxy" {
  project          = var.main_project_id
  name             = "${var.prefix}-gemini-enterprise-https-proxy"
  region           = var.region
  url_map          = google_compute_region_url_map.gemini_enterprise_load_balancer.id
  ssl_certificates = [data.google_compute_region_ssl_certificate.gemini_enterprise_cert.self_link]
}

# This resource creates the forwarding rule for the load balancer.
# This requires the SSL cert via the proxy to be uploaded, pending stage 00 and upload.
resource "google_compute_forwarding_rule" "gemini_enterprise_forwarding_rule" {
  project               = var.main_project_id
  name                  = "${var.prefix}-gemini-enterprise-forwarding-rule"
  region                = var.region
  ip_protocol           = "TCP"
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  network               = data.google_compute_network.gemini_enterprise_vpc.self_link
  ip_address            = data.google_compute_address.gemini_enterprise_ip.address
  target                = google_compute_region_target_https_proxy.gemini_enterprise_https_proxy.id
}

# --- IAP Access Roles ---
# Grant a user or group access through IAP.
# --- IAP Access Roles --- (CORRECT REGIONAL RESOURCE TYPE)
resource "google_iap_web_region_backend_service_iam_member" "iap_admin" {
  project                    = var.main_project_id
  region                     = var.region
  web_region_backend_service = data.google_compute_region_backend_service.gemini_enterprise_backend.name
  role                       = "roles/iap.httpsResourceAccessor"
  member                     = "group:${var.admin_group}@${var.domain}"
  condition {
    title       = "Admin Access"
    description = "Access for Admins with Strict Device Policy"
    expression  = format("\"accessPolicies/%s/accessLevels/strict_device\" in request.auth.access_levels", var.access_policy_number)
  }
}

resource "google_iap_web_region_backend_service_iam_member" "iap_user" {
  project                    = var.main_project_id
  region                     = var.region
  web_region_backend_service = data.google_compute_region_backend_service.gemini_enterprise_backend.name
  role                       = "roles/iap.httpsResourceAccessor"
  member                     = "group:${var.user_group}@${var.domain}"
  condition {
    title       = "User Access"
    description = "Access for Users with Moderate Device Policy"
    expression  = format("\"accessPolicies/%s/accessLevels/moderate_device\" in request.auth.access_levels", var.access_policy_number)
  }
}