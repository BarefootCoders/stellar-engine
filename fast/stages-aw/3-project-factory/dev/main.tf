/**
 * Copyright 2022 Google LLC
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

# tfdoc:file:description Project factory.

module "projects" {
  source = "../../../../modules/project-factory"
  data_defaults = {
    billing_account = var.billing_account.id
    # more defaults are available, check the project factory variables
    shared_vpc_service_config = {
      host_project = var.host_project_name
    }
  }
  data_merges = {
    labels = {
      environment = "dev"
    }
    services = [
      "stackdriver.googleapis.com"
    ]
  }
  data_overrides = {
    prefix = "${var.prefix}-dev"
  }
  factories_config = var.factories_config
}

# Get existing VPC from the existing project (MAIN PROJECT)
data "google_compute_network" "vpc" {
  project = var.host_project_name
  name    = var.peer_network_name
}

# Google VPC Module 
module "vpc" {
  source                          = "../../../../modules/net-vpc"
  for_each                        = module.projects.projects
  project_id                      = each.value.id
  name                            = "vpc-${lower(each.value.name)}"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
  routing_mode                    = "GLOBAL"
  subnets = [
    {
      name   = "subnet-${lower(each.value.name)}"
      region = "us-east1"
      #ip_cidr_range = "10.${((index(keys(module.projects.projects), "${lower(each.value.name)}-dev") + 1) * 100)}.0.0/22"
      #ip_cidr_range = "10.2${((index(keys(module.projects.projects), "${lower(each.value.name)}-dev") + 1) * 10)}.0.0/22"
      ip_cidr_range = "10.2${10 * (parseint(index(keys(module.projects.projects), "${lower(each.value.name)}-dev")) - 1)}.0.0/22"
    }
  ]
}

# Google VPC Network Peering module   
module "peering" {
  source        = "../../../../modules/net-vpc-peering"
  for_each      = module.vpc
  prefix        = "app-prod-peer"
  local_network = data.google_compute_network.vpc.self_link
  peer_network  = each.value.self_link
}


