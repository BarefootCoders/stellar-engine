# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

output "admin_group" {
  value       = var.admin_group
  description = "The principal for the Gemini Enterprise administrators group."
}

output "user_group" {
  value       = var.user_group
  description = "The principal for the Gemini Enterprise users group."
}

output "gemini_enterprise_ip" {
  value       = var.deployment_type == "internal" ? google_compute_address.gemini_enterprise_internal_ip[0].address : google_compute_address.gemini_enterprise_external_ip[0].address
  description = "The reserved IP address for the load balancer."
}

output "deployment_type" {
  value       = var.deployment_type
  description = "The deployment type of the load balancer (internal or external)."
}

output "tf_state_bucket_name" {
  value       = data.google_storage_bucket.terraform_state.name
  description = "The name of the GCS bucket used for Terraform state."
}

output "access_policy_number" {
  value       = var.access_policy_number
  description = "The Access Policy number."
}

output "domain" {
  value       = var.domain
  description = "The domain of the google organization."
}

output "main_project_id" {
  value       = var.main_project_id
  description = "The GCP Project name."
}

output "prefix" {
  value       = var.prefix
  description = "Prefix for naming resources."
}

output "region" {
  value       = var.region
  description = "GCP Region."
}

output "enable_chrome_enterprise_premium" {
  value       = var.enable_chrome_enterprise_premium
  description = "Whether Chrome Enterprise Premium (Zero Trust) is enabled."
}

output "use_shared_vpc" {
  value       = var.use_shared_vpc
  description = "Whether Shared VPC is used."
}

output "network_project_id" {
  value       = var.network_project_id
  description = "The Host Project ID."
}

output "shared_vpc_network_name" {
  value       = var.shared_vpc_network_name
  description = "The Shared VPC Network Name."
}

output "shared_vpc_subnet_name" {
  value       = var.shared_vpc_subnet_name
  description = "The Shared VPC Subnet Name."
}

output "shared_vpc_proxy_subnet_name" {
  value       = var.shared_vpc_proxy_subnet_name
  description = "The Shared VPC Proxy Subnet Name."
}