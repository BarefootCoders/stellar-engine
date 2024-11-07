resource "google_compute_global_address" "private_service_connect_ip" {
  for_each = var.envs_folders

  project = module.env-spoke-vpc[each.key].project_id
  name          = "default-peering"
  purpose       = "VPC_PEERING"
  # purpose = "PRIVATE_SERVICE_CONNECT"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = module.env-spoke-vpc[each.key].self_link
}

resource "google_service_networking_connection" "default" {
  for_each = var.envs_folders
  network                 = module.env-spoke-vpc[each.key].self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_connect_ip[each.key].name]
}
