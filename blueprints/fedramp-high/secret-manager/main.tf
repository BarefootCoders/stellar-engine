
locals {
    # Grab all the keys from the secrets variable in order to grant permissions to secret manager service account
    all_kms_keys = distinct(flatten([
        for secret_id, secret_data in var.secrets : [
             secret_data.key
        ]
    ]))

    # Convert the secret variable to a format that is usable by the module
    secrets = {
        for secret_id, secret_data in var.secrets : 
        secret_id => {
            locations = [secret_data.location]                  # Convert single string to list of strings
            keys = { (secret_data.location) = secret_data.key } # Convert single string to map of strings
        }
    }
}

# Enable the API service
resource "google_project_service" "secretmanager"{
    service = "secretmanager.googleapis.com"
    disable_on_destroy = false
}

data "google_project" "project" {
    project_id = var.project_id
}

# Grant permissions to secret manager service account
resource "google_kms_crypto_key_iam_member" "secretmanager"{
    for_each = toset(local.all_kms_keys)
    crypto_key_id = each.value
    role = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
    member = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-secretmanager.iam.gserviceaccount.com"
}

# Use the secret manager module to create the secrets
module "secret-manager"{
    source = "../../../modules/secret-manager"
    project_id = var.project_id
    secrets = local.secrets
    iam = var.iam
    depends_on = [ resource.google_kms_crypto_key_iam_member.secretmanager, 
                   resource.google_project_service.secretmanager ]
}