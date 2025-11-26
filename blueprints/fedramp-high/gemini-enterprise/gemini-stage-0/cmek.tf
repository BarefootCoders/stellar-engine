# Data source to read the keyring from the provided KMS Key ID (State Key)
data "google_kms_key_ring" "cmek_key_ring" {
  name     = element(split("/", var.kms_key_id), 5)
  location = element(split("/", var.kms_key_id), 3)
  project  = element(split("/", var.kms_key_id), 1)
}

resource "google_kms_crypto_key" "resources" {
  count           = var.create_resource_keys ? 1 : 0
  name            = "gemini-enterprise-cmek-key"
  key_ring        = data.google_kms_key_ring.cmek_key_ring.id
  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = true
  }
}
