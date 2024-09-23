# /**
#  * Copyright 2024 Google LLC
#  *
#  * Licensed under the Apache License, Version 2.0 (the "License");
#  * you may not use this file except in compliance with the License.
#  * You may obtain a copy of the License at
#  *
#  *      http://www.apache.org/licenses/LICENSE-2.0
#  *
#  * Unless required by applicable law or agreed to in writing, software
#  * distributed under the License is distributed on an "AS IS" BASIS,
#  * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  * See the License for the specific language governing permissions and
#  * limitations under the License.
#  */

# # tfdoc:file:description Lightweight tenant resources.

# # TODO(ludo): add support for CI/CD

locals {
  tenant_iam = {
    for k, v in local.tenant_envs : k => [
      v.tenant_info.admin_principal,
      module.tenant-self-iac-sa[k].iam_email
    ]
  }
  gcs_locations = { for k, v in var.tenants : k => try(v.locations.gcs != "", false) ? v.locations.gcs : var.locations.gcs }
  tenant_envs = merge([for e, _ in var.envs_folders : {
    for t, v in var.tenants : "${e}-${t}" => {
      env         = e
      tenant      = t
      tenant_info = v
    }
    }
  ]...)
}

# Tenant folders (top, core, self)
module "tenant-top-folders" {
  source   = "../../../modules/folder"
  for_each = local.tenant_envs
  parent   = module.branch-envs-folders[each.value.env].id
  name     = "Project ${each.value.tenant}"
  iam_by_principals = {
    (each.value.tenant_info.admin_principal) = ["roles/browser"]
  }
}

module "tenant-top-folders-iam" {
  source        = "../../../modules/folder"
  for_each      = local.tenant_envs
  id            = module.tenant-top-folders[each.key].id
  folder_create = false
  tag_bindings = {
    tenant = module.organization.tag_values["${var.tag_names.tenant}/${each.value.tenant}"].id
  }
  iam = merge(
    {
      "roles/cloudasset.owner"               = [module.tenant-core-sa[each.key].iam_email]
      "roles/compute.xpnAdmin"               = [module.tenant-core-sa[each.key].iam_email]
      "roles/logging.admin"                  = [module.tenant-core-sa[each.key].iam_email]
      "roles/resourcemanager.folderAdmin"    = [module.tenant-core-sa[each.key].iam_email]
      "roles/resourcemanager.projectCreator" = [module.tenant-core-sa[each.key].iam_email]
      "roles/resourcemanager.tagUser"        = [module.tenant-core-sa[each.key].iam_email]
    },
    {
      for k in var.tenants_config.top_folder_roles :
      k => local.tenant_iam[each.value.tenant.name]
    }
  )
}

module "tenant-core-folders" {
  source   = "../../../modules/folder"
  for_each = local.tenant_envs
  parent   = module.tenant-top-folders[each.key].id
  name     = "${each.value.tenant_info.descriptive_name} - Core"
}

module "tenant-core-folders-iam" {
  source        = "../../../modules/folder"
  for_each      = local.tenant_envs
  id            = module.tenant-core-folders[each.key].id
  folder_create = false
  iam = merge(
    {
      "roles/owner" = [
        module.tenant-core-sa[each.key].iam_email
      ]
      "roles/viewer" = local.tenant_iam[each.key]
    },
    {
      for k in var.tenants_config.core_folder_roles :
      k => local.tenant_iam[each.key]
    }
  )
}

module "tenant-self-folders" {
  source   = "../../../modules/folder"
  for_each = local.tenant_envs
  parent   = module.tenant-top-folders[each.key].id
  name     = "${each.value.tenant_info.descriptive_name} - Main"
}

module "tenant-self-folders-iam" {
  source        = "../../../modules/folder"
  for_each      = local.tenant_envs
  id            = module.tenant-self-folders[each.key].id
  folder_create = false
  iam = merge(
    {
      "roles/cloudasset.owner"               = [module.tenant-core-sa[each.key].iam_email]
      "roles/compute.xpnAdmin"               = [module.tenant-core-sa[each.key].iam_email]
      "roles/resourcemanager.folderAdmin"    = [module.tenant-core-sa[each.key].iam_email]
      "roles/resourcemanager.projectCreator" = [module.tenant-core-sa[each.key].iam_email]
      "roles/resourcemanager.tagUser"        = [module.tenant-core-sa[each.key].iam_email]
      "roles/owner"                          = [module.tenant-core-sa[each.key].iam_email]
    },
    {
      for k in var.tenants_config.tenant_folder_roles :
      k => local.tenant_iam[each.key]
    }
  )
}

# Tenant IaC resources (core)

module "tenant-core-sa" {
  source      = "../../../modules/iam-service-account"
  for_each    = local.tenant_envs
  project_id  = var.automation.project_id
  name        = lower("tn-${each.key}-prod-0")
  description = "Terraform service account for tenant ${each.key}."
  prefix      = var.prefix
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
}

module "tenant-core-gcs" {
  source     = "../../../modules/gcs"
  for_each   = local.tenant_envs
  project_id = var.automation.project_id
  name       = lower("tn-${each.key}-0")
  prefix     = var.prefix
  versioning = true
  location   = local.gcs_locations[each.value.tenant]
  storage_class = (
    length(split("-", local.gcs_locations[each.value.tenant])) < 2
    ? "MULTI_REGIONAL"
    : "REGIONAL"
  )
  # encryption_key = module.tenant-project-keys[each.key].key_ids["gcs"]
  depends_on = [module.tenant-project-keys]
  iam = {
    "roles/storage.objectAdmin" = [module.tenant-core-sa[each.key].iam_email]
  }
}

# Tenant IaC project and resources (self)
module "tenant-self-iac-projects" {
  source   = "../../../modules/project"
  for_each = local.tenant_envs
  billing_account = (
    each.value.tenant_info.billing_account != null
    ? each.value.tenant_info.billing_account
    : var.billing_account.id
  )
  name   = lower("${each.key}-iac-core-0")
  parent = module.tenant-core-folders[each.key].id
  prefix = var.prefix
  iam_by_principals = {
    (each.value.tenant_info.admin_principal) = [
      "roles/iam.serviceAccountAdmin",
      "roles/iam.serviceAccountTokenCreator",
      "roles/iam.workloadIdentityPoolAdmin"
    ]
  }
  iam = {
    (var.custom_roles.storage_viewer) = [
      "serviceAccount:${var.automation.service_accounts.resman-r}"
    ]
    "roles/viewer" = [
      "serviceAccount:${var.automation.service_accounts.resman-r}"
    ]
  }
  services = [
    "accesscontextmanager.googleapis.com",
    "bigquery.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerystorage.googleapis.com",
    "billingbudgets.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "container.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "essentialcontacts.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "orgpolicy.googleapis.com",
    "pubsub.googleapis.com",
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com",
    "stackdriver.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com",
    "sts.googleapis.com"
  ]
}

module "tenant-self-iac-gcs-outputs" {
  source     = "../../../modules/gcs"
  for_each   = local.tenant_envs
  project_id = module.tenant-self-iac-projects[each.key].project_id
  location   = local.gcs_locations[each.value.tenant]
  storage_class = (
    length(split("-", local.gcs_locations[each.value.tenant])) < 2
    ? "MULTI_REGIONAL"
    : "REGIONAL"
  )
  name       = "${each.key}-iac-outputs-0"
  prefix     = var.prefix
  versioning = true
  iam = {
    "roles/storage.objectAdmin" = [module.tenant-core-sa[each.key].iam_email]
  }
  encryption_key = module.tenant-project-keys[each.key].key_ids["gcs"]
  depends_on     = [module.tenant-project-keys]

}

module "tenant-project-keys" {
  source     = "../../../modules/kms"
  project_id = module.tenant-self-iac-projects[each.key].project_id
  for_each   = local.tenant_envs
  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
      module.tenant-core-sa[each.key].iam_email,
      "serviceAccount:service-${module.tenant-self-iac-projects[each.key].number}@gs-project-accounts.iam.gserviceaccount.com"
    ]
  }
  keyring = {
    name     = "${each.key}-keyring"
    location = try(each.value.locations.kms != "", false) ? each.value.locations.kms : var.locations.kms
  }
  keys = {
    gcs = {
      purpose         = "ENCRYPT_DECRYPT"
      labels          = { service = "gcs" }
      locations       = try(each.value.locations.kms != "", false) ? each.value.locations.kms : var.locations.kms
      rotation_period = "7776000s"
      version_template = {
        algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
        protection_level = "HSM"
      }
    }
  }
}

module "tenant-self-iac-gcs-states" {
  source     = "../../../modules/gcs"
  for_each   = local.tenant_envs
  project_id = module.tenant-self-iac-projects[each.key].project_id
  location   = local.gcs_locations[each.value.tenant]
  storage_class = (
    length(split("-", local.gcs_locations[each.value.tenant])) < 2
    ? "MULTI_REGIONAL"
    : "REGIONAL"
  )
  name           = "${each.key}-iac-0"
  prefix         = var.prefix
  versioning     = true
  encryption_key = module.tenant-project-keys[each.key].key_ids["gcs"]
  depends_on     = [module.tenant-project-keys]
}

module "tenant-self-iac-sa" {
  source      = "../../../modules/iam-service-account"
  for_each    = local.tenant_envs
  project_id  = module.tenant-self-iac-projects[each.key].project_id
  name        = lower("${each.key}-iac-0")
  description = "Terraform automation service account."
  prefix      = var.prefix
  iam_storage_roles = {
    (module.tenant-self-iac-gcs-outputs[each.key].name) = [
      "roles/storage.admin"
    ]
    (module.tenant-self-iac-gcs-states[each.key].name) = [
      "roles/storage.admin"
    ]
  }
}

# Tenant main project and resources (self)
module "tenant-self-main-projects" {
  source   = "../../../modules/project"
  for_each = local.tenant_envs
  billing_account = (
    each.value.tenant_info.billing_account != null
    ? each.value.tenant_info.billing_account
    : var.billing_account.id
  )
  name   = lower("${each.key}-main-0")
  parent = module.tenant-self-folders[each.key].id
  prefix = var.prefix
  iam_by_principals = {
    (each.value.tenant_info.admin_principal) = [
      "roles/iam.serviceAccountAdmin",
      "roles/iam.serviceAccountTokenCreator",
      "roles/iam.workloadIdentityPoolAdmin"
    ]
  }
  iam = {
    (var.custom_roles.storage_viewer) = [
      "serviceAccount:${var.automation.service_accounts.resman-r}"
    ]
    "roles/viewer" = [
      "serviceAccount:${var.automation.service_accounts.resman-r}"
    ]
  }
  compute_metadata = {
    google-compute-default-region = var.locations.gcs
    google-compute-default-zone = "${var.locations.gcs}-b" # There always seems to be a -b zone
  }
  services = [
    "accesscontextmanager.googleapis.com",
    "bigquery.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerystorage.googleapis.com",
    "billingbudgets.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "container.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "essentialcontacts.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "orgpolicy.googleapis.com",
    "pubsub.googleapis.com",
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com",
    "stackdriver.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com",
    "sts.googleapis.com"
  ]
}
