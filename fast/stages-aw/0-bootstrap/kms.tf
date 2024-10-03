locals {
  version_template = {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "HSM"
  }
}
module "logging-kms" {
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

module "gcs-kms" {
  source     = "../../../modules/kms"
  project_id = module.automation-project.project_id

  keyring = {
    location = local.locations.gcs
    name     = "gcs"
  }
  keys = {
    "gcs" = {
      version_template = local.version_template
    }
  }
  iam = {

    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
      "serviceAccount:service-${module.automation-project.number}@gs-project-accounts.iam.gserviceaccount.com",
      "serviceAccount:${var.prefix}-prod-resman-0@${var.prefix}-prod-iac-core-0.iam.gserviceaccount.com"
    ],
    "roles/cloudkms.viewer" = [
            "serviceAccount:${var.prefix}-prod-resman-0r@${var.prefix}-prod-iac-core-0.iam.gserviceaccount.com"
    ]
  }
}