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

locals {
  # routing_config should be aligned to the NVA network interfaces - i.e.
  # local.routing_config[0] sets up the first interface, and so on.
  routing_config = [
    {
      name                = "dmz"
      enable_masquerading = true
      routes = [
        var.gcp_ranges.gcp_dmz_primary,
        var.gcp_ranges.gcp_dmz_secondary,
      ]
    },
    {
      name = "landing"
      routes = [
        var.gcp_ranges.gcp_dev_primary,
        var.gcp_ranges.gcp_dev_secondary,
        var.gcp_ranges.gcp_landing_landing_primary,
        var.gcp_ranges.gcp_landing_landing_secondary,
        var.gcp_ranges.gcp_prod_primary,
        var.gcp_ranges.gcp_prod_secondary,
      ]
    },
  ]
  nva_locality = {
    for v in setproduct(["primary", ], local.nva_zones) :
    join("-", v) => {
      name   = v[0]
      region = var.regions[v[0]]
      zone   = v[1]
    }
  }
  nva_zones                     = ["b", "c"]
  cloud_storage_service_account = "service-${module.landing-project.number}@gs-project-accounts.iam.gserviceaccount.com"
  cloud_compute_service_account = "service-${module.landing-project.number}@compute-system.iam.gserviceaccount.com"
  ngfw_bootstrap_folders        = ["config/", "content/", "license/", "software/"]
  cidr_ranges                   = yamldecode(file("${path.module}/data/cidrs.yaml"))
}

data "google_compute_image" "vmseries" {
  family  = var.vmseries_image
  project = "paloaltonetworksgcp-public"
}

data "google_storage_project_service_account" "gcs_account" {
  project = module.landing-project.project_id
}

data "google_compute_default_service_account" "gce_account" {
  project = module.landing-project.project_id
}

resource "tls_private_key" "ngfw-ssh" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

# Shell out to openssl to get the password hash
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

module "ngfw-service-account" {
  name       = "ngfw-compute"
  source     = "../../../modules/iam-service-account"
  project_id = module.landing-project.project_id
  iam_project_roles = {
    "${module.landing-project.project_id}" = [
      "roles/logging.bucketWriter",
      "roles/opsconfigmonitoring.resourceMetadata.writer",
      "roles/autoscaling.metricsWriter",
      "roles/monitoring.metricWriter",
      "roles/storage.objectViewer",
      "roles/viewer"
    ]
  }
}

data "external" "openssl" {
  program = ["bash", "${path.module}/openssl-helper.sh"]

  query = {
    # arbitrary map from strings to strings, passed
    # to the external program as the data query.
    algo      = "5"
    plaintext = random_password.password.result
  }
}

# Google Cloud Storage Module 
module "ngfw-bootstrap-bucket" {
  source         = "../../../modules/gcs"
  prefix         = var.prefix
  project_id     = module.landing-project.project_id
  encryption_key = module.kms.keys.default.id
  name           = "ngfw-bootstrap"
  location       = "us"
  depends_on     = [module.kms]
}

resource "google_storage_bucket_iam_binding" "binding" {
  bucket = module.ngfw-bootstrap-bucket.name
  role   = "roles/storage.objectUser"
  members = [
    data.google_compute_default_service_account.gce_account.member,
    module.ngfw-service-account.service_account.member
  ]
}

# Google KMS Module
module "kms" {
  source     = "../../../modules/kms"
  project_id = module.landing-project.project_id
  keys       = var.keys
  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
      data.google_storage_project_service_account.gcs_account.member,
      "serviceAccount:${local.cloud_compute_service_account}",
    ]
  }
  keyring = {
    location = "us"
    name     = "landing-zone-keyring"
  }
  depends_on = [module.ngfw-service-account]
}

resource "google_storage_bucket_object" "config_folders" {
  for_each = toset(local.ngfw_bootstrap_folders)
  name     = each.value
  bucket   = module.ngfw-bootstrap-bucket.name
  content  = " "
}

resource "google_storage_bucket_object" "bootstrap-xml" {
  name = "config/bootstrap.xml"
  content = templatefile("./templates/bootstrap.xml.tpl", {
    password_hash     = data.external.openssl.result.hash
    ssh_pubkey        = tls_private_key.ngfw-ssh.public_key_openssh
    healthcheck_cidrs = local.cidr_ranges["healthchecks"]
    iap_cidrs         = local.cidr_ranges["iap"]
  })
  bucket = module.ngfw-bootstrap-bucket.name
}

resource "google_storage_bucket_object" "init-cfg" {
  name = "config/init-cfg.txt"
  content = templatefile("./templates/init-cfg.txt.tpl", {
    op-command-modes = "mgmt-interface-swap"
  })
  bucket = module.ngfw-bootstrap-bucket.name
}


module "ngfw-template" {
  for_each        = local.nva_locality
  source          = "../../../modules/compute-vm"
  project_id      = module.landing-project.project_id
  name            = "nva-template-${each.key}"
  zone            = "${each.value.region}-${each.value.zone}"
  instance_type   = "n2d-standard-4"
  tags            = ["nva"]
  create_template = true
  can_ip_forward  = true
  network_interfaces = [
    {
      network = module.dmz-vpc.self_link
      subnetwork = try(
        module.dmz-vpc.subnet_self_links["${each.value.region}/dmz-default"], null
      )
      nat       = true
      addresses = null
    },
    {
      network = module.mgmt-vpc.self_link
      subnetwork = try(
        module.mgmt-vpc.subnet_self_links["${each.value.region}/mgmt-default"], null
      )
      nat       = true
      addresses = null
    },
    {
      network = module.landing-vpc.self_link
      subnetwork = try(
        module.landing-vpc.subnet_self_links["${each.value.region}/landing-default"], null
      )
      nat       = false
      addresses = null
    }
  ]
  encryption = {
    encrypt_boot = true
    kms_key_self_link = module.kms.keys.default.id
  }
  boot_disk = {
    initialize_params = {
      image = data.google_compute_image.vmseries.self_link
      size  = 60
      type  = "pd-ssd"
    }
    kms_key_self_link = module.kms.keys.default.id
  }
  options = {
    allow_stopping_for_update = true
    deletion_protection       = false
    spot                      = true
    termination_action        = "STOP"
  }
  metadata = {
    mgmt-interface-swap                  = "enable"
    op-command-modes                     = "mgmt-interface-swap"
    dhcp-accept-server-domain            = "yes"
    dhcp-accept-server-hostname          = "yes"
    ssh-keys                             = "admin:${tls_private_key.ngfw-ssh.public_key_openssh}"
    serial-port-enable                   = "true"
    vmseries-bootstrap-gce-storagebucket = module.ngfw-bootstrap-bucket.name
  }
  service_account = {
    email = module.ngfw-service-account.email
    # scopes = [
    #   "https://www.googleapis.com/auth/compute.readonly",
    #   "https://www.googleapis.com/auth/cloud.useraccounts.readonly",
    #   "https://www.googleapis.com/auth/devstorage.read_only",
    #   "https://www.googleapis.com/auth/logging.write",
    #   "https://www.googleapis.com/auth/monitoring.write",
    # ]
  }
}

module "nva-mig" {
  for_each          = local.nva_locality
  source            = "../../../modules/compute-mig"
  project_id        = module.landing-project.project_id
  location          = each.value.region
  name              = "nva-ngfw-${each.key}"
  instance_template = module.ngfw-template[each.key].template.self_link
  target_size       = 1
  auto_healing_policies = {
    initial_delay_sec = 600
  }
  health_check_config = {
    tcp = {
      port = 22
    }
  }
}

module "ilb-nva-dmz" {
  for_each = {
    for k, v in var.regions : k => {
      region = v
      subnet = "${v}/dmz-default"
    }
  }
  source        = "../../../modules/net-lb-int"
  project_id    = module.landing-project.project_id
  region        = each.value.region
  name          = "nva-dmz-${each.key}"
  service_label = var.prefix
  forwarding_rules_config = {
    "" = {
      global_access = true
    }
  }
  vpc_config = {
    network    = module.dmz-vpc.self_link
    subnetwork = try(module.dmz-vpc.subnet_self_links[each.value.subnet], null)
  }
  backends = [
    for k, v in module.nva-mig :
    { group = v.group_manager.instance_group }
    if startswith(k, each.key)
  ]
  health_check_config = {
    enable_logging = true
    tcp = {
      port = 22
    }
  }
}

module "ilb-nva-landing" {
  for_each = {
    for k, v in var.regions : k => {
      region = v
      subnet = "${v}/landing-default"
    }
  }
  source        = "../../../modules/net-lb-int"
  project_id    = module.landing-project.project_id
  region        = each.value.region
  name          = "nva-landing-${each.key}"
  service_label = var.prefix
  forwarding_rules_config = {
    "" = {
      global_access = true
    }
  }
  vpc_config = {
    network    = module.landing-vpc.self_link
    subnetwork = try(module.landing-vpc.subnet_self_links[each.value.subnet], null)
  }
  backends = [
    for k, v in module.nva-mig :
    { group = v.group_manager.instance_group }
    if startswith(k, each.key)
  ]
  health_check_config = {
    enable_logging = true
    tcp = {
      port = 22
    }
  }
}

resource "google_compute_route" "primary-landing-default" {
  name         = "default-route-primary-ngfw-lb"
  project      = module.landing-project.project_id
  description  = "Primary route to the internet through NGFWs"
  dest_range   = "0.0.0.0/0"
  network      = module.landing-vpc.name
  next_hop_ilb = module.ilb-nva-landing.primary.forwarding_rules[""].self_link
  priority     = 100
}

resource "google_compute_route" "secondary-landing-default" {
  name         = "default-route-secondary-ngfw-lb"
  project      = module.landing-project.project_id
  description  = "Secondary route to the internet through backup NGFWs"
  dest_range   = "0.0.0.0/0"
  network      = module.landing-vpc.name
  next_hop_ilb = module.ilb-nva-landing.secondary.forwarding_rules[""].self_link
  priority     = 200
}