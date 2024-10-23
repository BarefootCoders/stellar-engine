output "ids"{
    description = "Secret IDs."
    value = module.secret-manager.ids
}

output "secrets"{
    description = "Secret resources."
    value = module.secret-manager.secrets
}

output "version_ids"{
    description = "Version ids keyed by secret name : version name."
    value = module.secret-manager.version_ids
}

output "versions" {
    description = "Secret versions."
    value       = module.secret-manager.versions
    sensitive   = true
}
