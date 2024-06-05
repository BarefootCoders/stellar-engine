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

locals {
  base        = "10.200.0.0/24"
  subnet_cidr = cidrsubnet(local.base, 8, 0)

  # List all YAML files in the directory
  yaml_files = fileset("${path.root}/data/dev", "*.yaml")
  # Read and decode each YAML file to extract the name
  projects = [
    for file in local.yaml_files : {
      name        = yamldecode(file("${path.root}/data/dev/${file}")).name
      subnet_cidr = local.subnet_cidr
    }
  ]
}

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


module "vpc" {
  source                          = "../../../../modules/net-vpc"
  for_each                        = toset(local.projects)
  project_id                      = each.value.id
  name                            = "vpc-${each.value.name}"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
  routing_mode                    = "GLOBAL"
  subnets = [
    {
      name          = "${each.value.name}-subnet"
      region        = var.location
      ip_cidr_range = each.value.subnet_cidr
    }
  ]
}
