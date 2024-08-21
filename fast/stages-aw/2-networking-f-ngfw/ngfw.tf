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
  # tflint-ignore: terraform_unused_declarations
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
  nva_zones   = ["b", "c"]
  cidr_ranges = yamldecode(file("${path.module}/data/cidrs.yaml"))

  cloud_compute_service_account = "service-${module.landing-project.number}@compute-system.iam.gserviceaccount.com"
}

data "google_compute_image" "vmseries" {
  filter      = "name=vmseries-flex-byol-1113 AND family=${var.vmseries_image}"
  most_recent = true
  project     = "paloaltonetworksgcp-public"
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

# Shell out to openssl to get the password hash
resource "random_password" "salt" {
  length  = 8
  special = false
}

resource "google_project_iam_custom_role" "ngfw-custom-role" {
  role_id = "ngfw.appliance"
  title   = "NGFW Appliance"
  project = module.landing-project.project_id

  description = "Many of the permissions required for the Palo Alto NGFW, not including compute.viewer"
  permissions = [
    "storage.buckets.get",
    "logging.buckets.write",
    "opsconfigmonitoring.resourceMetadata.write",
    "autoscaling.sites.writeMetrics",
    "monitoring.metricDescriptors.create",
    "monitoring.metricDescriptors.get",
    "monitoring.metricDescriptors.list",
    "monitoring.monitoredResourceDescriptors.get",
    "monitoring.monitoredResourceDescriptors.list",
    "monitoring.timeSeries.create",
  ]
}

module "ngfw-service-account" {
  name       = "ngfw-compute"
  source     = "../../../modules/iam-service-account"
  project_id = module.landing-project.project_id
  iam_project_roles = {
    (module.landing-project.project_id) = [
      google_project_iam_custom_role.ngfw-custom-role.id,
      "roles/compute.viewer"
    ]
  }
  depends_on = [module.landing-project, google_project_iam_custom_role.ngfw-custom-role]
}

data "external" "openssl" {
  program = ["bash", "${path.module}/openssl-helper.sh"]
  query = {
    # arbitrary map from strings to strings, passed
    # to the external program as the data query.
    algo      = "5"
    salt      = random_password.salt.result
    plaintext = random_password.password.result
  }
}

# Google Cloud Storage Module
module "ngfw-bootstrap-bucket" {
  source         = "../../../modules/gcs"
  for_each       = var.regions
  prefix         = var.prefix
  project_id     = module.landing-project.project_id
  encryption_key = module.kms[each.key].keys.default.id
  storage_class  = "REGIONAL"
  name           = "ngfw-bootstrap-${each.value}"
  location       = upper(each.value)
  depends_on     = [module.kms, module.kms["primary"], module.kms["secondary"]]
}

resource "google_storage_bucket_iam_binding" "binding" {
  bucket   = module.ngfw-bootstrap-bucket[each.key].name
  for_each = var.regions
  role     = "roles/storage.objectUser"
  members = [
    "serviceAccount:service-${module.landing-project.number}@compute-system.iam.gserviceaccount.com",
    module.ngfw-service-account.service_account.member
  ]
}

resource "time_sleep" "wait_180_seconds" {
  depends_on = [module.landing-project]

  create_duration = "180s"
}

# Google KMS Module
module "kms" {
  source     = "../../../modules/kms"
  for_each   = var.regions
  project_id = module.landing-project.project_id
  keys       = var.keys
  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
      "serviceAccount:service-${module.landing-project.number}@gs-project-accounts.iam.gserviceaccount.com",
      "serviceAccount:service-${module.landing-project.number}@compute-system.iam.gserviceaccount.com",
      "serviceAccount:${local.cloud_compute_service_account}"
    ]
  }
  keyring = {
    location = each.value
    name     = "landing-zone-keyring"
    version_template = {
      algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
      protection_level = "HSM"
    }
  }
  depends_on = [
    module.ngfw-service-account,
    module.landing-project,
    time_sleep.wait_180_seconds
  ]
}

resource "google_storage_bucket_object" "config_folders" {
  for_each = var.regions
  name     = "config/"
  bucket   = module.ngfw-bootstrap-bucket[each.key].name
  content  = " "
}

resource "google_storage_bucket_object" "content_folders" {
  for_each = var.regions
  name     = "content/"
  bucket   = module.ngfw-bootstrap-bucket[each.key].name
  content  = " "
}

resource "google_storage_bucket_object" "software_folders" {
  for_each = var.regions
  name     = "software/"
  bucket   = module.ngfw-bootstrap-bucket[each.key].name
  content  = " "
}

resource "google_storage_bucket_object" "license_folders" {
  for_each = var.regions
  name     = "license/"
  bucket   = module.ngfw-bootstrap-bucket[each.key].name
  content  = " "
}

resource "google_storage_bucket_object" "bootstrap-xml" {
  name     = "config/bootstrap.xml"
  for_each = var.regions
  content = templatefile("./templates/bootstrap.xml.tpl", {
    password_hash     = data.external.openssl.result.hash
    ssh_pubkey        = tls_private_key.ngfw-ssh.public_key_openssh
    healthcheck_cidrs = local.cidr_ranges["healthchecks"]
    iap_cidrs         = local.cidr_ranges["iap"]
    tenants_subnet    = local.cidr_ranges["tenants"][0]
    lz_gateway_ip     = module.landing-vpc.subnets["us-east4/landing-default"].gateway_address # This doesn't support dual region yet

  })
  bucket = module.ngfw-bootstrap-bucket[each.key].name
}

resource "google_storage_bucket_object" "init-cfg" {
  name     = "config/init-cfg.txt"
  for_each = var.regions

  content = templatefile("./templates/init-cfg.txt.tpl", {
    op-command-modes = "mgmt-interface-swap"
  })
  bucket = module.ngfw-bootstrap-bucket[each.key].name
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
      nat       = true # we can't turn this off until we figure out Private Service Connect
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
    encrypt_boot      = true
    kms_key_self_link = module.kms[each.value.name].keys.default.id

  }
  boot_disk = {
    initialize_params = {
      image = data.google_compute_image.vmseries.self_link
      size  = 60
      type  = "pd-ssd"
    }
    kms_key_self_link = module.kms[each.value.name].keys.default.id
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
    vmseries-bootstrap-gce-storagebucket = module.ngfw-bootstrap-bucket[each.value.name].name
  }
  service_account = {
    email = module.ngfw-service-account.email
  }
  depends_on = [module.kms, module.kms["secondary"], module.kms["primary"]]
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