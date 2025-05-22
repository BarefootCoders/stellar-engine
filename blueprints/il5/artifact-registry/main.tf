locals {
  repositories = merge([
    for f in try(fileset("data/", "*.yaml"), []) :
    yamldecode(file("data/${f}"))
  ]...)

  docker-registries = merge(google_artifact_registry_repository.docker-repos, { "docker-hub" = google_artifact_registry_repository.docker-hub })
}

data "google_project" "project" {
  project_id = var.main_project_id
}

data "google_kms_key_ring" "default" {
  name     = var.kms_keyring_name
  location = var.region
  project  = var.core_project_id
}

data "google_kms_crypto_key" "default" {
  name     = var.kms_key_name
  key_ring = data.google_kms_key_ring.default.id
}

resource "google_project_service_identity" "artifact_registry_agent" {
  provider = google-beta
  project  = var.main_project_id
  service  = "artifactregistry.googleapis.com"

  depends_on = [
    google_project_service.api
  ]
}

resource "google_project_service" "api" {
  for_each           = toset(["artifactregistry.googleapis.com", "containerscanning.googleapis.com"])
  project            = data.google_project.project.id
  service            = each.value
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "yum-repos" {
  location      = var.region
  for_each      = local.repositories.yum
  repository_id = each.key
  description   = "Remote copy of ${each.key}"
  format        = "YUM"
  mode          = "REMOTE_REPOSITORY"
  remote_repository_config {
    description = "Upstream repository for ${each.key}"
    yum_repository {
      public_repository {
        repository_base = each.value.remote.base
        repository_path = each.value.remote.path
      }
    }
  }
  kms_key_name = data.google_kms_crypto_key.default.id
  depends_on = [
    google_project_service.api,
    google_kms_crypto_key_iam_member.artifact_registry_crypto_key
  ]
}

resource "google_artifact_registry_repository" "docker-hub" {
  location      = var.region
  repository_id = "docker-hub"
  description   = "Pull through registry for Docker Hub"
  format        = "DOCKER"
  mode          = "REMOTE_REPOSITORY"
  remote_repository_config {
    disable_upstream_validation = false
    description                 = "docker hub"
    docker_repository {
      public_repository = "DOCKER_HUB"
    }
  }

  kms_key_name = data.google_kms_crypto_key.default.id
  depends_on = [
    google_project_service.api,
    google_kms_crypto_key_iam_member.artifact_registry_crypto_key
  ]
}

resource "google_artifact_registry_repository" "docker-repos" {
  location      = var.region
  for_each      = local.repositories.docker
  repository_id = each.key
  description   = "Remote copy of ${each.key}"
  format        = "DOCKER"
  mode          = "REMOTE_REPOSITORY"
  remote_repository_config {
    description = "Upstream repository for ${each.key}"
    docker_repository {
      custom_repository {
        uri = each.value.remote.uri
      }
    }
  }
  kms_key_name = data.google_kms_crypto_key.default.id
  depends_on = [
    google_project_service.api,
    google_kms_crypto_key_iam_member.artifact_registry_crypto_key
  ]
}

resource "google_kms_crypto_key_iam_member" "artifact_registry_crypto_key" {
  crypto_key_id = data.google_kms_crypto_key.default.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = google_project_service_identity.artifact_registry_agent.member
  depends_on = [
    google_project_service_identity.artifact_registry_agent
  ]
}