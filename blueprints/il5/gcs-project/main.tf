#Google Cloud Storage Module service
module "cloud_storage" {
  source                   = "../../../modules/gcs"
  project_id               = var.project_id
  name                     = var.name
  location                 = var.location
  autoclass                = var.autoclass
  versioning               = var.versioning
  storage_class            = var.storage_class
  public_access_prevention = var.public_access_prevention
  force_destroy            = var.force_destroy
  encryption_key           = var.encryption_key

}