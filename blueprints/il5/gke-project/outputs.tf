output "gke_cluster_name" {
  description = "The name of the GKE cluster."
  value       = module.cluster-1.name
}

output "gke_cluster_endpoint" {
  description = "The endpoint of the GKE cluster."
  value       = module.cluster-1.endpoint
}

# output "keyring-id" {
#   description = "Fully qualified keyring id."
#   value       = module.kms.id
# }

# output "keyring-resource" {
#   description = "Keyring resource."
#   value       = module.kms.keyring
# }

# output "qualified_key_ids" {
#   description = "Fully qualified key ids."
#   value       = module.kms.key_ids
# }

# output "keyrings-keys" {
#   description = "Key resources."
#   value       = module.kms.keys
# }

# output "keyring-name" {
#   description = "Keyring name."
#   value       = module.kms.name
# }

# output "keyring-location" {
#   description = "Keyring location."
#   value       = module.kms.location
# }
