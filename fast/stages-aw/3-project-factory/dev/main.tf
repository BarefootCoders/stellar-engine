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

# List all YAML files in the data/projects directory
locals {
  yaml_files = fileset("${path.module}/data/projects", "*.yaml")
  file_contents = {
    for file in data.local_file.yaml_files : file.filename => yamldecode(file.content)
  }
  file_names = {
    for file, content in local.file_contents : file => content.name
  }
  project_contents = {
    for file, content in local.file_contents : content.name => content
  }
  project_names = keys(local.file_names)
  projects = {
    for idx in range(length(local.project_names)) :
    local.project_names[idx] => {
      name = local.file_names[local.project_names[idx]]
    }
  }
}

# Get existing vpc from existing project (Main project)
data "google_compute_network" "vpc" {
  project = var.host_project_ids["prod-landing"]
  name    = regex("networks/([^/]+)$", var.vpc_self_links["prod-landing"])[0]
}

# Read the content of the YAML files
data "local_file" "yaml_files" {
  for_each = toset(local.yaml_files)
  filename = "${path.module}/data/projects/${each.value}"
}


module "projects" {
  source = "../../../../modules/project-factory"
  data_defaults = {
    billing_account = var.billing_account.id
    # more defaults are available, check the project factory variables
    shared_vpc_service_config = {
      host_project = var.host_project_ids["prod-landing"]
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

# Create Google VPC using modules
module "vpc" {
  source                          = "../../../../modules/net-vpc"
  for_each                        = local.projects
  project_id                      = "${var.prefix}-dev-${basename(trimsuffix(each.key, ".yaml"))}"
  name                            = "vpc-${var.prefix}-${each.value.name}"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
  routing_mode                    = "GLOBAL"
  subnets = [
    {
      name          = "subnet-${var.prefix}-${each.value.name}"
      region        = local.project_contents[each.value.name].subnetregion
      ip_cidr_range = local.project_contents[each.value.name].subnetcidr
    }
  ]

  depends_on = [module.projects]
}


# Create VPC peering using Google Module
# Google Cloud Platform (GCP) VPC peering has a maximum of 25 connections per project to a single VPC network.
module "peering" {
  source        = "../../../../modules/net-vpc-peering"
  for_each      = module.vpc
  prefix        = var.prefix
  local_network = data.google_compute_network.vpc.self_link
  peer_network  = each.value.self_link

  depends_on = [module.projects, module.vpc]
}