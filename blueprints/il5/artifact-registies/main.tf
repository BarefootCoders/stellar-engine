locals {
  repositories = merge([
    for f in try(fileset("data/", "*.yaml"), []) :
    yamldecode(file("data/${f}"))
  ]...)
}

data "google_project" "project" {}

module "kms" {
  source     = "../../../modules/kms"
  project_id = var.project
  keys       = var.keys
  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
      google_service_account.consumer.member,
      "serviceAccount:service-${data.google_project.project.number}@compute-system.iam.gserviceaccount.com",
      "serviceAccount:service-${data.google_project.project.number}@gcp-sa-artifactregistry.iam.gserviceaccount.com"
    ]
  }
  keyring = {
    name     = var.keyring
    location = var.region
  }
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
  kms_key_name = module.kms.keys["artifact-registry"].id
  depends_on = [
    module.kms
  ]
}

resource "google_artifact_registry_repository" "docker-hub" {
  location      = var.region
  repository_id = "docker-hub"
  description   = "Pull through registry for Docker Hub"
  format        = "DOCKER"
  mode          = "REMOTE_REPOSITORY"
  remote_repository_config {
    description = "docker hub"
    docker_repository {
      public_repository = "DOCKER_HUB"
    }
  }
  kms_key_name = module.kms.keys["artifact-registry"].id
  depends_on = [
    module.kms
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
  kms_key_name = module.kms.keys["artifact-registry"].id
  depends_on = [
    module.kms
  ]
}

# Configure Google AOSS
# External registeration required here https://developers.google.com/assured-oss#get-started

# resource "google_artifact_registry_repository" "aoss-python" {
#   location      = var.region
#   repository_id = "aoss-python"
#   description   = "Google Assured Open Source Software"
#   format        = "PYTHON"
#   mode          = "REMOTE_REPOSITORY"
#   remote_repository_config {
#     description                 = "Manage connection here https://developers.google.com/assured-oss#get-started"
#     disable_upstream_validation = true
#     python_repository {
#       custom_repository {
#         uri = "https://us-python.pkg.dev/cloud-aoss/python/simple/"
#       }
#     }
#   }
# }



