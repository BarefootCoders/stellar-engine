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
output "bucket_name" {
  description = "The name of the bucket"
  value       = google_storage_bucket.dataflow_bucket.name
}

output "bucket_url" {
  description = "The URL of the created bucket"
  value       = "https://console.cloud.google.com/storage/browser/${google_storage_bucket.dataflow_bucket.name}?project=${var.project_id}"
}

output "kms_key_self_link" {
  description = "The self link of the default KMS key"
  value       = module.kms.keys.default.id
}

output "compute_service_account_email" {
  description = "The email of the compute service account"
  value       = google_service_account.compute.email
}