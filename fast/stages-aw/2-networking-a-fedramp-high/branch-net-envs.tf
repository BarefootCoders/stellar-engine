/**
 * Copyright 2023 Google LLC
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

# tfdoc:file:description Dev spoke VPC and related resources.

module "env-spoke-projects" {
  source          = "../../../modules/project"
  for_each        = var.envs_folders
  billing_account = var.billing_account.id
  name            = lower("${each.key}-net-host")
  parent          = var.folder_ids.networking
  prefix          = var.prefix
  services = concat([
    "container.googleapis.com",
    "compute.googleapis.com",
    "dns.googleapis.com",
    "iap.googleapis.com",
    "networkmanagement.googleapis.com",
    "servicenetworking.googleapis.com",
    "stackdriver.googleapis.com",
    "vpcaccess.googleapis.com"
    ]
  )
  shared_vpc_host_config = {
    enabled = true
  }
  metric_scopes = [module.vdss-host-project.project_id]
  iam = {
    "roles/dns.admin" = compact([
      try(local.service_accounts.gke-dev, null),
      try(local.service_accounts.project-factory-dev, null),
      try(local.service_accounts.project-factory-prod, null),
    ])
  }
  #   # allow specific service accounts to assign a set of roles
  #   iam_bindings = {
  #     sa_delegated_grants = {
  #       role = "roles/resourcemanager.projectIamAdmin"
  #       members = compact([
  #         try(local.service_accounts.data-platform-dev, null),
  #         try(local.service_accounts.project-factory-dev, null),
  #         try(local.service_accounts.project-factory-prod, null),
  #         try(local.service_accounts.gke-dev, null),
  #       ])
  #       condition = {
  #         title       = "dev_stage3_sa_delegated_grants"
  #         description = "Development host project delegated grants."
  #         expression = format(
  #           "api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([%s])",
  #           join(",", formatlist("'%s'", local.stage3_sas_delegated_grants))
  #         )
  #       }
  #     }
  #   }
}


module "env-spoke-vpc" {
  source   = "../../../modules/net-vpc"
  for_each = var.envs_folders

  project_id = module.env-spoke-projects[each.key].project_id

  name = lower("${each.key}-spoke-0")
  mtu  = 1500
  dns_policy = {
    logging = var.dns.enable_logging
  }
  delete_default_routes_on_create = true
  psa_configs                     = var.psa_ranges.dev
  # Set explicit routes for googleapis; send everything else to NVAs
  create_googleapis_routes = {
    private    = true
    restricted = true
  }
}

resource "google_network_connectivity_internal_range" "reserved_ranges" {
  for_each          = var.envs_folders
  name              = lower("${each.key}-range")
  project           = module.env-spoke-projects[each.key].project_id
  description       = "Automatically reserved range for ${each.key}"
  network           = module.env-spoke-vpc[each.key].id
  usage             = "FOR_VPC"
  peering           = "FOR_SELF"
  prefix_length     = 22
  target_cidr_range = ["10.64.0.0/16", ]
}

resource "google_compute_subnetwork" "defaults" {
  provider                = google-beta
  for_each                = var.envs_folders
  name                    = lower("${each.key}-default-0")
  project                 = module.env-spoke-projects[each.key].project_id
  reserved_internal_range = google_network_connectivity_internal_range.reserved_ranges[each.key].ip_cidr_range
  region                  = var.regions.primary
  network                 = module.env-spoke-vpc[each.key].id
}

module "env-spoke-firewall" {
  source   = "../../../modules/net-vpc-firewall"
  for_each = var.envs_folders

  project_id = module.env-spoke-projects[each.key].project_id
  network    = module.env-spoke-vpc[each.key].name
  default_rules_config = {
    disabled = true
  }
  factories_config = {
    cidr_tpl_file = "${var.factories_config.data_dir}/cidrs.yaml"
    rules_folder  = lower("${var.factories_config.data_dir}/firewall-rules/${each.key}")
  }
}

module "peering-envs" {
  source   = "../../../modules/net-vpc-peering"
  for_each = var.envs_folders

  prefix        = lower("${each.key}-peering-0")
  local_network = module.env-spoke-vpc[each.key].self_link
  peer_network  = module.vdss-vpc.self_link
  routes_config = {
    local = {
      public_import = true
    }
    peer = {
      public_export = true
    }
  }

}
