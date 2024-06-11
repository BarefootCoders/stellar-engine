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

# Terraform Provider for Google Cloud Platform
provider "google" {
  project = var.project_id
  region  = var.location
}

# Work on the Current Project
data "google_project" "current" {}

# Get existing vpc from existing project (Main project)
data "google_compute_network" "vpc" {
  project = var.host_project_name
  name    = var.peer_network_name
}

# Google VPC Module
module "vpc" {
  source                          = "../../../modules/net-vpc"
  project_id                      = var.project_id
  name                            = "vpc-project-${data.google_project.current.number}"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
  routing_mode                    = "GLOBAL"
  # Divided from 10.200.12.0/23
  subnets = [
    {
      name          = "subnet-${data.google_project.current.number}-a"
      region        = var.location
      description   = "Subnet a simple subnet"
      ip_cidr_range = var.subnets_cidr_a
    },
    # custom description and PGA disabled
    {
      name                  = "subnet-${data.google_project.current.number}-no-pga-b"
      region                = var.location
      ip_cidr_range         = var.subnets_cidr_b
      description           = "Subnet b with no PGA"
      enable_private_access = false
    },
    # secondary ranges
    {
      name          = "subnet-${data.google_project.current.number}-secondary-ranges"
      region        = var.location
      ip_cidr_range = var.subnets_cidr_c
      description   = "Subnet c with secondary ranges"
      secondary_ip_ranges = {
        a = "192.168.0.0/24"
        b = "192.168.1.0/24"
      }
    }
  ]
}

# Create VPC peering using Google Module 
# Google Cloud Platform (GCP) VPC peering has a maximum of 25 connections per project to a single VPC network. 
module "peering" {
  source        = "../../../modules/net-vpc-peering"
  prefix        = "peer"
  local_network = data.google_compute_network.vpc.self_link
  peer_network  = module.vpc.id
}