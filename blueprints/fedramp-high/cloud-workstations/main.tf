locals {
  landing_project = var.landing_project == null ? var.project : var.landing_project
  kms_project     = var.kms_project == null ? var.project : var.kms_project

  network_config = {
    network    = "projects/${local.landing_project}/global/networks/${var.network}"
    subnetwork = "projects/${local.landing_project}/regions/${var.region}/subnetworks/${var.subnet}"
  }
  key = "projects/${local.kms_project}/locations/${var.region}/keyRings/${var.keyring}/cryptoKeys/${var.key}"

  compute_default_sa     = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  workstation_default_sa = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-workstations.iam.gserviceaccount.com"

  workstations = {
    for workstation, config in var.workstations : workstation => merge(
      config,
      {
        iam = (
          lookup(config, "users", null) != null ? {
            "roles/workstations.user" = config.users
          } : {}
        )
      }
    )
  }
}

# Enable the API service
resource "google_project_service" "workstations" {
  project = var.project
  for_each = toset([
    "workstations.googleapis.com",
    "compute.googleapis.com",
  ])
  service            = each.key
  disable_on_destroy = false
}

data "google_project" "project" {}

module "workstations" {
  source         = "../../../modules/workstation-cluster"
  id             = var.cluster_id
  project_id     = var.project
  location       = var.region
  network_config = local.network_config
  # private_cluster_config = {
  #   enable_private_endpoint = true
  # }
  workstation_configs = {
    (var.config_id) = {
      container = var.image == null ? null : {
        image = var.image
      }
      encryption_key = {
        kms_key                 = local.key
        kms_key_service_account = google_service_account.workstation_config_key_user.email
      }
      gce_instance = {
        machine_type                = var.machine_type
        disable_public_ip_addresses = true
        shielded_instance_config = {
          enable_secure_boot          = true
          enable_vtpm                 = true
          enable_integrity_monitoring = true
        }
      }
      workstations = local.workstations
    }
  }
  depends_on = [
    google_kms_crypto_key_iam_member.workstations_sa_kms_permissions,
    google_project_iam_member.artifact_registry_reader,
    google_project_iam_member.network_user
  ]
}