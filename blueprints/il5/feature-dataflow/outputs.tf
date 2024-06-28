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
output "dataflow_service_account_email" {
  description = "Email of dataflow service account"
  value       = google_service_account.dataflow.email
}
output "bucket_name" {
  description = "Name of Google Cloud storage bucket"
  value       = module.gcs.bucket.name
}

output "dataflow_job_name" {
  description = "Name of dataflow job name"
  value       = module.dataflow_job.name
}

output "template_gcs_path" {
  description = "Name of template_gcs_path"
  value       = module.dataflow_job.template_gcs_path
}

output "temp_gcs_location" {
  description = "Name of template_gcs_location"
  value       = module.dataflow_job.temp_gcs_location
}

output "pubsub_topic_name" {
  description = "Name of pubsub topic."
  value       = data.google_pubsub_topic.topic.name
}

output "bigquery_dataset_id" {
  description = "Name of dataset id."
  value       = data.google_bigquery_dataset.dataset.dataset_id
}

output "bigquery_table_id" {
  description = "Name of dataset table id."
  value       = var.bigquery_table_id
}




