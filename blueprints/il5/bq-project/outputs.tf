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


output "keyring" {
  value = module.kms.keyring
}

output "dataset_name" {
  value = module.bigquery-dataset.id
}

output "materialized_views" {
  value = module.bigquery-dataset.materialized_views
}

output "materialized_view_ids" {
  value = module.bigquery-dataset.materialized_view_ids
}

output "self_link" {
  value = module.bigquery-dataset.self_link
}

output "table_ids" {
  value = module.bigquery-dataset.table_ids
}

output "tables" {
  value = module.bigquery-dataset.tables
}

output "view_ids" {
  value = module.bigquery-dataset.view_ids
}

output "views" {
  value = module.bigquery-dataset.views
}
