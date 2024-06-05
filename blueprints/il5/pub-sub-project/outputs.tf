output "crypto_key_id"{
    value = google_kms_crypto_key.id
}

output "key_ring_id"{
    value = google_kms_key_ring.id
}