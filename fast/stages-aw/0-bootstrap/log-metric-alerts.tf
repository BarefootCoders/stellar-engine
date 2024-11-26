# CIS Compliance Benchmark 2.4, 2.5, 2.6, 2.7, 2.8, 2.0, 2.10, 2.11

locals {
  bootstrap_projects = [
    module.log-export-project.id,
    module.automation-project.id,
  module.billing-export-project[0].id]
}

module "bootstrap_log_metrics" {
  source = "../../../modules/cis-log-metrics"

  for_each = toset(local.bootstrap_projects)
  project  = each.key
}

# Alerts require log-metrics to be configure
resource "time_sleep" "bootstrap_wait_10_seconds" {
  depends_on      = [module.bootstrap_log_metrics]
  create_duration = "10s"
}

module "bootstrap_log_alerts" {
  source = "../../../modules/cis-log-alerts"

  for_each = toset(local.bootstrap_projects)

  project            = each.key
  combiner           = "OR"
  duration           = "60s"
  comparison         = "COMPARISON_GT"
  alignment_period   = "60s"
  per_series_aligner = "ALIGN_RATE"
  alert_email        = var.alert_email

  depends_on = [time_sleep.bootstrap_wait_10_seconds]
}
