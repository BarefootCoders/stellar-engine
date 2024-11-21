# Requires App Engine Instance
module "datastore" {
  source  = "terraform-google-modules/cloud-datastore/google"
  version = "~> 2.0"
  project = var.project_id
  indexes = file("index.yaml")
}
