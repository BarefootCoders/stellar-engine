# Sample VM that uses the registries from Artifact Registry to do nothing in particular

resource "google_service_account" "consumer" {
  account_id   = "compute-service-account"
  display_name = "Customized service account for consumer"
}

# IAM role for the consumer service account
# The Default Compute service account also has readonly access by default
resource "google_project_iam_member" "consumer-readonly" {
  project = var.project
  role    = "roles/artifactregistry.reader"
  member  = google_service_account.consumer.member
}

data "google_compute_network" "my-network" {
  name = var.compute_vpc
}

data "google_compute_image" "centos" {
  family  = "centos-stream-9"
  project = "centos-cloud"
}

# Google Compute Engine VM Module
module "compute-engine-vm" {
  source        = "../../../modules/compute-vm"
  project_id    = var.project
  zone          = "${var.region}-b"
  name          = "rpm-consumer"
  instance_type = "e2-medium"
  network_interfaces = [{
    network    = data.google_compute_network.my-network.id
    subnetwork = data.google_compute_network.my-network.subnetworks_self_links[0]
  }]
  encryption = {
    kms_key_self_link = module.kms.keys.artifact-registry.id
  }
  metadata = {
    startup-script = templatefile("./templates/userdata.tftpl",
      {
        project          = var.project
        region           = var.region
        yum_repositories = google_artifact_registry_repository.yum-repos
      }
    )
  }

  service_account = {
    email = google_service_account.consumer.email
  }
  # Persistent Disk Attached to the Compute Engine with KMS
  boot_disk = {
    initialize_params = {
      auto_delete       = true
      size              = 20
      type              = "pd-balanced"
      image             = data.google_compute_image.centos.self_link
      kms_key_self_link = module.kms.keys.artifact-registry.id
    }
  }
  depends_on = [module.kms]
}