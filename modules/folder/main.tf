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

locals {
  folder = (
    var.folder_create
    ? var.compliance.regime != ""
    ? try(data.google_folder.aw_folder[0], null)
    : try(google_folder.folder[0], null)
    : try(data.google_folder.folder[0], null)
  )
}


resource "google_assured_workloads_workload" "assured_workload_folder" {
  count             = var.compliance.regime != "" ? 1 : 0
  compliance_regime = var.compliance.regime
  display_name      = var.name
  location          = var.compliance.location
  organization      = var.compliance.organization

  provisioned_resources_parent = strcontains(var.parent, "folders/") ? var.parent : ""

  resource_settings {
    resource_type = "CONSUMER_FOLDER"
  }

  violation_notifications_enabled = true
  labels = {
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "time_sleep" "wait_30_seconds" {
  depends_on      = [google_assured_workloads_workload.assured_workload_folder]
  create_duration = "30s"
}

data "google_folder" "aw_folder" {
  depends_on = [google_assured_workloads_workload.assured_workload_folder]
  count      = var.compliance.regime != "" ? 1 : 0
  folder     = "folders/${google_assured_workloads_workload.assured_workload_folder[0].resources[0].resource_id}"
}



data "google_folder" "folder" {
  count  = var.folder_create ? 0 : 1
  folder = var.id
}

resource "google_folder" "folder" {
  count        = (var.folder_create && var.compliance.regime == "") ? 1 : 0
  display_name = var.name
  parent       = var.parent
}

resource "google_essential_contacts_contact" "contact" {
  provider                            = google-beta
  for_each                            = var.contacts
  parent                              = local.folder.name
  email                               = each.key
  language_tag                        = "en"
  notification_category_subscriptions = each.value
  depends_on = [
    google_folder_iam_binding.authoritative,
    google_folder_iam_binding.bindings,
    google_folder_iam_member.bindings
  ]
}

resource "google_compute_firewall_policy_association" "default" {
  count             = var.firewall_policy == null ? 0 : 1
  attachment_target = local.folder.id
  name              = var.firewall_policy.name
  firewall_policy   = var.firewall_policy.policy
}
