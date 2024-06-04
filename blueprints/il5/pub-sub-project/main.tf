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
#Terraform Provider for Google Cloud Platform
provider "google" { 
 project = var.project_id 
 region  = var.location
 } 

#Google KMS Module
module "kms" {
  source     = "../../../modules/kms"
  project_id = var.project_id
  keys       = var.keys
  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
      google_service_account.compute.member,
      "serviceAccount:service-${data.google_project.current.number}@compute-system.iam.gserviceaccount.com",
      "user:${var.service_account_email}"
    ]
  }
  keyring = var.keyring
}

resource "google_pubsub_topic" "pubsub_topic" {
  name             = var.pubsub_topic_name
  kms_key_name     = google_kms_crypto_key.crypto_key.id
}

 resource "google_pubsub_topic_iam_binding" "pubsub_topic_admin" {
  topic = google_pubsub_topic.pubsub_topic.name
  role  = "roles/pubsub.admin"
  members = var.admin_members
}
resource "google_pubsub_topic_iam_binding" "pubsub_topic_publisher" {
  topic = google_pubsub_topic.pubsub_topic.name
  role  = "roles/pubsub.publisher"
  members = var.publisher_members
}
resource "google_pubsub_topic_iam_binding" "pubsub_topic_subscriber" {
  topic = google_pubsub_topic.pubsub_topic.name
  role  = "roles/pubsub.subscriber"
  members = var.subscriber_members

}
resource "google_pubsub_subscription" "pubsub_subscription" {
  name  = var.pubsub_subscription_name
  topic = google_pubsub_topic.pubsub_topic.name
}

