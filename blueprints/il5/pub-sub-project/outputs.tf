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
 output "pubsub_admin_members" {
  description = "The members assigned the Pub/Sub admin role."
  value       = [for member in google_project_iam_member.pubsub_admin : member.member]
}

 output "service_account_email" {
  description = "This is the email of the Pub/Sub service account."
  value       = google_service_account.pubsub_service_account.email
}

output "pubsub_subscription_name" {
  description = "This is the name of the Pub/Sub subscription."
  value       = google_pubsub_subscription.pb_subscription.name
}

output "pubsub_topic_name" {
  description = "This is the name of the Pub/Sub topic."
  value       = google_pubsub_topic.pb_topic.name
}

output "iam_roles_members" {
  description = "These are the IAM members."
  value = {
    owner  = [for member in google_project_iam_member.project_owner : member.member],
    viewer = [for member in google_project_iam_member.project_viewer : member.member],
    editor = [for member in google_project_iam_member.project_editor : member.member]
  }
}