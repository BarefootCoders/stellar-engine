module "cloud_spanner" {
  source     = "../../../modules/spanner-instance"
  project_id = var.project
  instance = {
    name         = var.instance_name
    display_name = var.display_name
    config = {
      name = var.config_name
    }
    autoscaling = {
      limits = {
        min_processing_units = var.min_processing_units
        max_processing_units = var.max_processing_units
      }
      targets = {
        high_priority_cpu_utilization_percent = var.high_priority_cpu_utilization_percent
        storage_utilization_percent           = var.storage_utilization_percent
      }
    }
  }

  databases = {
    (var.database_name) = {
      iam = {
        "roles/spanner.databaseUser" = [
          var.database_user
        ]
      }
    }
  }
}