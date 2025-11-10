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

# This resource defines the URL map with the specified routing rules.
resource "google_compute_region_url_map" "cnap_url_map" {
  project               = var.main_project_id
  name            = "${var.prefix}-cloud-native-access-point-url-map"
  region          = var.region
  description     = "URL map for ${var.prefix}-cloud-native-access-point"
  default_service = google_compute_region_backend_service.gemini_enterprise_backend.id

  host_rule {
    hosts        = ["gemini-enterprise.kat-agentplus-dev.com"]
    path_matcher = "path-matcher-1"
  }

  path_matcher {
    name            = "path-matcher-1"
    default_service = google_compute_region_backend_service.gemini_enterprise_backend.id

    route_rules {
      priority = 100
      match_rules {
        prefix_match = "/"
      }
      service = google_compute_region_backend_service.gemini_enterprise_backend.id
      route_action {
        url_rewrite {
          host_rewrite        = "vertexaisearch.cloud.google.com"
          path_prefix_rewrite = "/us/home/cid/e73074c1-afa0-47d7-86ac-5f29057d6f04?hl=en_US"
        }
      }
    }
  }
}

# This resource creates the target HTTPS proxy for the load balancer.
# It now references the pre-existing SSL certificate via the data source.
resource "google_compute_region_target_https_proxy" "cnap_https_proxy" {
  project               = var.main_project_id
  name             = "${var.prefix}-cloud-native-access-point-https-proxy"
  region           = var.region
  url_map          = google_compute_region_url_map.cnap_url_map.id
  ssl_certificates = [data.google_compute_region_ssl_certificate.cnap_certificate.self_link]
}

# This resource creates the forwarding rule for the load balancer.
# This requires the SSL cert via the proxy to be uploaded, pending stage 00 and upload.
resource "google_compute_forwarding_rule" "gemini_enterprise_forwarding_rule" {
  project               = var.main_project_id
  name                  = "${var.prefix}-gemini-enterprise-forwarding-rule"
  region                = var.region
  ip_protocol           = "TCP"
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL"
  network               = data.google_compute_network.network.self_link
  ip_address            = google_compute_address.gemini_enterprise_ip.address
  target                = google_compute_region_target_https_proxy.gemini_enterprise_https_proxy.id
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
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL"
  network               = data.google_compute_network.gemini_enterprise_vpc.self_link
  ip_address            = google_compute_address.gemini_enterprise_ip.address
  target                = google_compute_region_target_http_proxy.gemini_enterprise_http_proxy.id
}