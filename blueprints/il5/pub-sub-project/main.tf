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

#Create publisher account 
resource "google_service_account" "publisher" {
  account_id = var.publisher_account_id
  display_name       = var.publisher_name
}

#Create subscriber account 
resource "google_service_account" "subscriber" {
  account_id   = var.subscriber_account_id
  display_name         = var.subscriber_name
}

#IAM role for the publisher service account
resource "google_project_iam_member" "pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.publisher.email}"
}

#IAM role for the subscriber service account
resource "google_project_iam_member" "pubsub_subscriber" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.subscriber.email}"
}

#Google KMS Module 
module "kms" {
  source     = "../../../modules/kms"
  project_id = var.project_id
  keys       = var.keys
  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
      google_service_account.publisher.email,
      google_service_account.subscriber.email
    ]
  }
  keyring = var.keyring
}

# Create a Pub/Sub topic with allowed persistence regions
resource "google_pubsub_topic" "pubsub_topic" {
  name                        = var.pubsub_topic_name
  kms_key_name                = module.kms.keys
  #allowed_persistence_regions = var.allowed_persistence_regions
}

# IAM role bindings for publisher account
resource "google_pubsub_topic_iam_member" "publisher" {
  topic  = google_pubsub_topic.pubsub_topic.name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${google_service_account.publisher.email}"
}

#IAM role bindings for subscriber account
resource "google_pubsub_subscription_iam_member" "subscriber" {
  subscription = google_pubsub_subscription.pubsub_subscription.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.subscriber.email}"
}

# Creating a Pub/Sub subscription
resource "google_pubsub_subscription" "pubsub_subscription" {
  name                 = var.pubsub_subscription_name
  topic                = google_pubsub_topic.pubsub_topic.name
  ack_deadline_seconds = 20
  push_config {
    #create push endpoint
    push_endpoint = var.push_endpoint
  }
}