#Enable the API service
resource "google_project_service" "secretmanager"{
    service = "secretmanager.googleapis.com"
}

data "google_project" "project" {}

#use the secret manager module to create the secrets
module "secret-manager"{
    source = "../../../modules/secret-manager"
    project_id = var.project_id
    secrets = var.secrets
    iam = var.iam
    versions = var.versions
}
