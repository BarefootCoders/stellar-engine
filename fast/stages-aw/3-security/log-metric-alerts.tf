# CIS Compliance Benchmark 2.4, 2.5, 2.6, 2.7, 2.8, 2.0, 2.10, 2.11

locals {
  security_projects = [
    module.dev-sec-project.id,
    module.prod-sec-project.id
  ]
}

module "security_log_metrics" {
  source = "../../../modules/cis-log-metrics"

  for_each = toset(local.security_projects)
  project  = each.key
}

# Alerts require log-metrics to be configure
resource "time_sleep" "security_wait_10_seconds" {
  depends_on      = [module.security_log_metrics]
  create_duration = "10s"
}

module "security_log_alerts" {
  source = "../../../modules/cis-log-alerts"

  for_each = toset(local.security_projects)
  project  = each.key

  combiner           = "OR"
  duration           = "60s"
  comparison         = "COMPARISON_GT"
  alignment_period   = "60s"
  per_series_aligner = "ALIGN_RATE"
  alert_email        = var.alert_email

  depends_on = [time_sleep.security_wait_10_seconds]
}
