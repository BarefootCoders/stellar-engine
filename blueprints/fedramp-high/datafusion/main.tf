module "datafusion" {
  source                   = "../../../modules/datafusion-se"
  name                     = var.name
  region                   = var.region
  project_id               = var.project_id
  network                  = var.network
  subnet                   = var.subnet
  firewall_create          = false
  landing_project_id       = var.landing_project_id
  dataproc_service_account = google_service_account.datafusion.email
  private_instance         = true
  kms_key                  = var.kms_key
  ip_allocation_create     = false
  network_peering          = false

  depends_on = [
    google_project_iam_member.network_user_main,
    google_project_iam_member.network_user_lz,
    google_kms_crypto_key_iam_binding.datafusion
  ]
}
