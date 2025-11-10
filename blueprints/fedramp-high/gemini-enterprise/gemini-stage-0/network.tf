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

# ---------------------------------------------------------------------------- #
#  Networking Resources                                                        #
# ---------------------------------------------------------------------------- #

resource "google_compute_network" "gemini_enterprise_vpc" {
  project                 = var.main_project_id
  name                    = "gemini-enterprise-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gemini_enterprise_vpc_subnet" {
  project                  = var.main_project_id
  name                     = "gemini-enterprise-vpc-subnet"
  ip_cidr_range            = "10.10.10.0/24"
  region                   = var.region
  network                  = google_compute_network.gemini_enterprise_vpc.id
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "gemini_enterprise_vpc_proxy_subnet" {
  project                  = var.main_project_id
  name                     = "gemini-enterprise-vpc-proxy-subnet"
  ip_cidr_range            = "10.10.11.0/24"
  region                   = var.region
  network                  = google_compute_network.gemini_enterprise_vpc.id
  purpose                  = "REGIONAL_MANAGED_PROXY"
  role                     = "ACTIVE"
}

resource "google_compute_address" "gemini_enterprise_ip" {
  project      = var.main_project_id
  name         = "gemini-enterprise-ip"
  region       = var.region
  address_type = "EXTERNAL"
}

# -----------------------------------------------------------------------------
# Internet NEG for vertexaisearch.cloud.google.com FQDN
# -----------------------------------------------------------------------------
resource "google_compute_region_network_endpoint_group" "gemini_enterprise_neg" {
  name = "gemini-enterprise-internet-neg"
  project               = var.main_project_id
  network               = data.google_compute_network.network.id
  network_endpoint_type = "INTERNET_FQDN_PORT"
  region                = var.region
}

resource "google_compute_region_network_endpoint" "gemini_enterprise_endpoint" {
  project                       = var.main_project_id
  region_network_endpoint_group = google_compute_region_network_endpoint_group.gemini_enterprise_neg.name
  region                        = var.region
  fqdn                          = "vertexaisearch.cloud.google.com"
  port                          = 443
}



