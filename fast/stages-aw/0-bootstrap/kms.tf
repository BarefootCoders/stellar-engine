locals {
  version_template = {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "HSM"
  }
}
module "kms" {
  source     = "../../../modules/kms"
  project_id = module.log-export-project.project_id

  keyring = {
    location = local.locations.logging
    name     = "logging"
  }
  keys = {
    "log-sink" = {
      version_template = local.version_template
    }
  }
  iam_bindings_additive = {
    "pubsub" = {
      member = "serviceAccount:service-${module.log-export-project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
      role   = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
    },
    "bq" = {
      member = "serviceAccount:bq-${module.log-export-project.number}@bigquery-encryption.iam.gserviceaccount.com"
      role   = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
    },
    "gcs" = {
      member = "serviceAccount:service-${module.log-export-project.number}@gs-project-accounts.iam.gserviceaccount.com"
      role   = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
    }
  }
}