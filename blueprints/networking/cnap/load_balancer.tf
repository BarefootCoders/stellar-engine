locals {
  cr_backends = { for key, _ in try(local.cloud_runs, {}) : key =>
    {
      backends = [
        { backend = "neg-${key}" }
      ]
      id            = ""
      health_checks = []
      port_name     = ""
      iap_config = {
        oauth2_client_id     = google_iap_client.project_client.client_id
        oauth2_client_secret = google_iap_client.project_client.secret
      }
    }
  }
  vm_backends = { for key, _ in local.vms : key =>
    {
      backends = [{
        backend       = module.cos-mig[key].group_manager.instance_group
        health_checks = [module.cos-mig[key].health_check.self_link]
        port_name     = "http"
      }]
    }
  }
  backends = merge(local.cr_backends, local.vm_backends)

  host_rules = [for key, values in local.apps : {
    hosts        = ["${values.subdomain}.${var.domain}"],
    path_matcher = "path-matcher-${key}"
  }]
  lb_name       = "${var.prefix}-cloud-native-access-point"
  service_names = { for app, _ in local.apps : app => "https://www.googleapis.com/compute/v1/projects/${var.project}/regions/${var.region}/backendServices/${local.lb_name}-${app}" }
}

data "google_compute_network" "network" {
  name    = "prod-dmz-0"
  project = var.landing_project_id
}
data "google_compute_subnetwork" "subnet" {
  name    = "us-east4-proxy-dmz"
  project = var.landing_project_id
  region  = var.region
}

resource "google_compute_shared_vpc_host_project" "host" {
  project = var.landing_project_id
}

resource "tls_private_key" "default" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

data "google_compute_network" "landing-vpc" {
  name    = var.network
  project = try(var.net_project, var.project)
}
resource "tls_self_signed_cert" "default" {
  private_key_pem = tls_private_key.default.private_key_pem
  subject {
    common_name  = var.domain
    organization = "ACME Examples, Inc"
  }
  dns_names = concat(
    [for app, _ in local.apps : "${app}.${var.domain}"],
    [for vm, _ in local.vms : "${vm}.${var.domain}"]
  )
  validity_period_hours = 720
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "google_compute_region_ssl_certificate" "default" {
  region      = var.region
  name_prefix = "${var.prefix}-cert-"
  description = "Self-signed demo cert"
  certificate = tls_self_signed_cert.default.cert_pem
  private_key = tls_private_key.default.private_key_pem

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_address" "cnap-ext-ip" {
  name         = "cnap-ip"
  region       = var.region
  address_type = "EXTERNAL"
  network_tier = "STANDARD"
}

module "cnap-0-redirect" {
  source     = "../../../modules/net-lb-app-ext-regional/"
  project_id = var.landing_project_id
  name       = "${var.prefix}-cloud-native-access-point-redirect"
  vpc        = data.google_compute_network.landing-vpc.self_link
  region     = var.region
  address = (
    google_compute_address.cnap-ext-ip.id
  )
  health_check_configs = {}
  urlmap_config = {
    description = "URL redirect for ${var.prefix}-cloud-native-access-point."
    default_url_redirect = {
      https         = true
      response_code = "MOVED_PERMANENTLY_DEFAULT"
    }
  }
  depends_on = [google_org_policy_policy.allow_external_lb]
}

module "cnap-0" {
  source     = "../../../modules/net-lb-app-ext-regional/"
  project_id = var.project
  name       = local.lb_name
  vpc        = data.google_compute_network.landing-vpc.self_link
  region     = var.region
  address = (
    google_compute_address.cnap-ext-ip.id
  )
  backend_service_configs = local.backends
  # with a single serverless NEG the implied default health check is not needed
  health_check_configs = {}
  neg_configs = { for key, _ in local.cloud_runs : "neg-${key}" =>
    {
      project = var.project
      cloudrun = {
        region = var.region
        target_service = {
          name = google_cloud_run_v2_service.cloud_run_apps[key].name
        }
      }
  } }

  urlmap_config = {
    default_service = local.service_names[var.default_backend]
    host_rules      = local.host_rules
    path_matchers = { for app, values in local.cloud_runs : "path-matcher-${app}" => {
      paths           = ["/*"],
      default_service = local.service_names[app]
      }
    }

  }
  protocol = "HTTPS"
  ssl_certificates = {
    certificate_ids = [google_compute_region_ssl_certificate.default.id]
  }

  depends_on = [google_cloud_run_v2_service.cloud_run_apps] # google_org_policy_policy.allow_external_lb]
}
