/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# Get Peering Network Information with Peer Host Project 
data "google_compute_network" "peer_vpc" {
  project = var.current_project_id
  name    = var.vpc_network_name
}

# Google VPC Module
module "vpc" {
  source                          = "../../../modules/net-vpc"
  project_id                      = var.current_project_id
  name                            = var.vpc_name
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
  routing_mode                    = "REGIONAL"
  # Divided from 10.200.12.0/23
  subnets = [
    {
      name          = "${var.subnet_prefix_name}-a"
      region        = var.location
      description   = "Subnet a simple subnet"
      ip_cidr_range = var.subnets_cidr_a
    },
    # custom description and PGA disabled
    {
      name                  = "${var.subnet_prefix_name}-b-no-pga"
      region                = var.location
      ip_cidr_range         = var.subnets_cidr_b
      description           = "Subnet b with no PGA"
      enable_private_access = false
    },
    # secondary ranges
    {
      name          = "${var.subnet_prefix_name}-c-secondary-ranges"
      region        = var.location
      ip_cidr_range = var.subnets_cidr_c
      description   = "Subnet c with secondary ranges"
      secondary_ip_ranges = {
        a = var.secondary_ip_ranges_cidr_a
        b = var.secondary_ip_ranges_cidr_b
      }
    }
  ]
}

# Create VPC peering using Google Module 
# Google Cloud Platform (GCP) VPC peering has a maximum of 25 connections per project to a single VPC network. 
module "peering" {
  source        = "../../../modules/net-vpc-peering"
  prefix        = "peer"
  local_network = data.google_compute_network.peer_vpc.self_link
  peer_network  = module.vpc.id
}