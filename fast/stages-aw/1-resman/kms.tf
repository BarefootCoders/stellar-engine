module "tenant-project-keys" {
  source     = "../../../modules/kms"
  project_id = module.tenant-self-iac-projects[each.key].project_id
  for_each   = local.tenant_envs
  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
      module.tenant-core-sa[each.key].iam_email,
      "serviceAccount:service-${var.automation.project_number}@gs-project-accounts.iam.gserviceaccount.com"
    ]
  }
  keyring = {
    name     = "${each.key}-keyring"
    location = try(each.value.locations.kms != "", false) ? each.value.locations.kms : var.locations.kms
  }
  keys = {
    gcs = {
      purpose         = "ENCRYPT_DECRYPT"
      labels          = { service = "gcs" }
      locations       = try(each.value.locations.kms != "", false) ? each.value.locations.kms : var.locations.kms
      rotation_period = "7776000s" # Compliant with CIS IAM 1.10
      version_template = {
        algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
        protection_level = "HSM"
      }
    }
  }
}

resource "google_kms_crypto_key_iam_member" "resman_bootstrap_kms" {
  for_each      = local.tenant_envs
  crypto_key_id = "projects/${var.automation.project_id}/locations/${var.locations.kms}/keyRings/gcs/cryptoKeys/gcs"
  member        = "serviceAccount:service-${module.tenant-self-iac-projects[each.key].number}@gs-project-accounts.iam.gserviceaccount.com"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
}

resource "google_kms_crypto_key_iam_member" "tenant_kms" {
  for_each      = local.tenant_envs
  crypto_key_id = module.tenant-project-keys[each.key].key_ids["gcs"]
  member        = "serviceAccount:service-${module.tenant-self-iac-projects[each.key].number}@gs-project-accounts.iam.gserviceaccount.com"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
}

# projects/il5-prod-iac-core-0/locations/us-east4/keyRings/gcs/cryptoKeys/gcs
# projects/il5-prod-iac-core-0/locations/us-east4/keyRings/gcs/cryptoKeys/gcs
