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

module "cloud_ids" {
  source                       = "../../../modules/intrusion-detection-system"
  project                      = var.landing_project_id
  landing_vpc_network          = var.landing_vpc_network
  network_region               = var.region
  network_zone                 = var.network_zone
  landing_network              = var.landing_vpc_network
  subnet                       = var.subnet
  subnet_list                  = var.subnet_list
  ids_private_ip_range_name    = "ids-private-address"
  ids_private_ip_prefix_length = var.ids_private_ip_prefix_length
  ids_name                     = var.ids_name
  severity                     = var.severity
  packet_mirroring_policy_name = var.packet_mirroring_policy_name
}