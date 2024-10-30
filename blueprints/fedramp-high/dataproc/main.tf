
# Step 1: Create Service Account
# Step 2: Give it the proper role

module "dataproc-service-account" {
  source     = "../../../modules/iam-service-account"
  project_id = var.project_id
  name       = "dataproc-worker"
  iam_project_roles = {
    (var.project_id) = ["roles/dataproc.worker"]
  }
}

module "firewall" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = var.project_id
  network    = var.network
  ingress_rules = {
    allow-ingress-dataproc = {
      description = "Allow all traffic between Dataproc nodes."
      targets     = ["dataproc"]
      sources     = ["dataproc"]
    }
  }
}

module "processing-dp-cluster" {
  source     = "../../../modules/dataproc"
  project_id = var.project_id
  name       = "my-cluster"
  region     = var.region
  dataproc_config = {
    cluster_config = {
      gce_cluster_config = {
        internal_ip_only       = true
        service_account        = module.dataproc-service-account.email
        service_account_scopes = ["cloud-platform"]
        subnetwork             = var.subnet
        tags                   = ["dataproc"]
        zone                   = "${var.region}-b"
      }
    }
    encryption_config = {
      kms_key_name = var.kms_key
    }
  }
  depends_on = [
    module.dataproc-service-account, # ensure all grants are done before creating the cluster
  ]
}