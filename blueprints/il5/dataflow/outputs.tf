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
  description = "Email of the Dataflow service account"
  value       = google_service_account.dataflow.email
}

output "bigquery_dataset_id" {
  description = "ID of the BigQuery dataset"
  value       = google_bigquery_dataset.dataset.dataset_id
}

output "bigquery_table_id" {
  description = "ID of the BigQuery table"
  value       = google_bigquery_table.table.table_id
}

output "pubsub_topic_name" {
  description = "Name of the Pub/Sub topic"
  value       = google_pubsub_topic.topic.name
}

output "pubsub_subscription_name" {
  description = "Name of the Pub/Sub subscription"
  value       = google_pubsub_subscription.subscription.name
}

output "kms_key_name" {
  description = "Name of the KMS key used for encryption"
  value       = module.kms.keys.key-dataflow.id
}

output "gcs_bucket_name" {
  description = "Name of the Google Cloud Storage bucket"
  value       = module.gcs.name
}

output "dataflow_job_name" {
  description = "Name of the Dataflow job"
  value       = google_dataflow_job.job.name
}








