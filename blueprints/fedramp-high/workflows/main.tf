module "workflows" {
  source = "../../../modules/workflows"
  project = var.project
  name                = var.name
  region              = var.region
  description         = var.description
  logging_level      = var.logging_level
  env_vars       = var.env_vars
  key     = var.key
  file = var.file
}