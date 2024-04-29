# Google Project
# Google Cloud Storage Module 


module "project" {
  source = "../../../modules/project"
  #source = "../../../modules/project"
  billing_account = (var.project_create != null
    ? var.project_create.billing_account_id
    : null
  )
  parent = (var.project_create != null
    ? var.project_create.parent
    : null
  )
  name = var.project_id
  services = [
    "run.googleapis.com",
    "compute.googleapis.com",
    "iap.googleapis.com"
  ]
  project_create = var.project_create != null
}

#Google Cloud Storage Module service
module "cloud_storage" {
  source                   = "../../../modules/gcs"
  project_id               = module.project.project_id
  name                     = var.name
  location                 = var.location
  autoclass                = var.autoclass
  versioning               = var.versioning
  storage_class            = var.storage_class
  public_access_prevention = var.public_access_prevention

}