# Google Compute Shielded VM Module
module "bastion-vm" {
  source     = "../../../modules/compute-vm"
  project_id = module.landing-project.project_id
  zone       = "${var.regions["primary"]}-c"
  name       = "management-bastion"
  shielded_config = {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
  tags          = ["bastion"]
  instance_type = "e2-small"
  network_interfaces = [{
    network = module.mgmt-vpc.self_link
    subnetwork = try(
      module.mgmt-vpc.subnet_self_links["${var.regions["primary"]}/mgmt-default"], null
    )
  }]
  encryption = {
    kms_key_self_link = module.kms["primary"].keys.default.id
  }
  attached_disks = [
    {
      auto_delete = true
      size        = 10
      name        = "data-disk"
      initialize_params = {
        image = "projects/cos-cloud/global/images/family/cos-stable"
      }
      kms_key_self_link = module.kms["primary"].keys.default.id
    }
  ]
  depends_on = [module.kms, module.kms["primary"], module.kms["secondary"]]
}