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
  count                   = var.use_shared_vpc ? 0 : 1
  project                 = var.main_project_id
  name                    = "gemini-enterprise-vpc"
  auto_create_subnetworks = false
}

data "google_compute_network" "shared_vpc" {
  count   = var.use_shared_vpc ? 1 : 0
  project = var.network_project_id
  name    = var.shared_vpc_network_name
}

resource "google_compute_subnetwork" "gemini_enterprise_vpc_subnet" {
  count                    = var.use_shared_vpc ? 0 : 1
  project                  = var.main_project_id
  name                     = "gemini-enterprise-vpc-subnet"
  ip_cidr_range            = var.internal_lb_subnet_range
  region                   = var.region
  network                  = google_compute_network.gemini_enterprise_vpc[0].id
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "gemini_enterprise_vpc_proxy_subnet" {
  count         = var.use_shared_vpc ? 0 : 1
  project       = var.main_project_id
  name          = "gemini-enterprise-vpc-proxy-subnet"
  ip_cidr_range = "10.10.11.0/24"
  region        = var.region
  network       = google_compute_network.gemini_enterprise_vpc[0].id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

data "google_compute_subnetwork" "shared_subnet" {
  count   = var.use_shared_vpc ? 1 : 0
  project = var.network_project_id
  region  = var.region
  name    = var.shared_vpc_subnet_name
}

data "google_compute_subnetwork" "shared_proxy_subnet" {
  count   = var.use_shared_vpc ? 1 : 0
  project = var.network_project_id
  region  = var.region
  name    = var.shared_vpc_proxy_subnet_name
}

locals {
  vpc_network_id      = var.use_shared_vpc ? data.google_compute_network.shared_vpc[0].id : google_compute_network.gemini_enterprise_vpc[0].id
  vpc_subnet_id       = var.use_shared_vpc ? data.google_compute_subnetwork.shared_subnet[0].id : google_compute_subnetwork.gemini_enterprise_vpc_subnet[0].id
  vpc_proxy_subnet_id = var.use_shared_vpc ? data.google_compute_subnetwork.shared_proxy_subnet[0].id : google_compute_subnetwork.gemini_enterprise_vpc_proxy_subnet[0].id
}

resource "google_compute_address" "gemini_enterprise_internal_ip" {
  count        = var.deployment_type == "internal" ? 1 : 0
  project      = var.main_project_id
  name         = "gemini-enterprise-internal-ip"
  region       = var.region
  subnetwork   = local.vpc_subnet_id
  address_type = "INTERNAL"
}

resource "google_compute_address" "gemini_enterprise_external_ip" {
  count        = var.deployment_type == "external" ? 1 : 0
  project      = var.main_project_id
  name         = "gemini-enterprise-external-ip"
  region       = var.region
  address_type = "EXTERNAL"
}

# -----------------------------------------------------------------------------
# Internet NEG for vertexaisearch.cloud.google.com FQDN
# -----------------------------------------------------------------------------
resource "google_compute_region_network_endpoint_group" "gemini_enterprise_neg" {
  name = "gemini-enterprise-internet-neg"
  project               = var.main_project_id
  network               = local.vpc_network_id
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



