# CIS Compliance Benchmark 2.4, 2.5, 2.6, 2.7, 2.8, 2.0, 2.10, 2.11

module "core_log_metrics" {
  source = "../../../modules/cis-log-metrics"

  for_each = module.tenant-self-iac-projects
  project  = module.tenant-self-iac-projects[each.key].id
}

module "main_log_metrics" {
  source = "../../../modules/cis-log-metrics"

  for_each = module.tenant-self-main-projects
  project  = module.tenant-self-main-projects[each.key].id
}

# Alerts require log-metrics to be configure
resource "time_sleep" "resman_wait_10_seconds" {
  depends_on      = [module.core_log_metrics, module.main_log_metrics]
  create_duration = "10s"
}

module "core_log_alerts" {
  source = "../../../modules/cis-log-alerts"

  for_each = module.tenant-self-iac-projects

  project            = module.tenant-self-iac-projects[each.key].id
  combiner           = "OR"
  duration           = "60s"
  comparison         = "COMPARISON_GT"
  alignment_period   = "60s"
  per_series_aligner = "ALIGN_RATE"
  alert_email        = var.alert_email

  depends_on = [time_sleep.resman_wait_10_seconds]
}

module "main_log_alerts" {
  source = "../../../modules/cis-log-alerts"

  for_each = module.tenant-self-main-projects

  project            = module.tenant-self-main-projects[each.key].id
  combiner           = "OR"
  duration           = "60s"
  comparison         = "COMPARISON_GT"
  alignment_period   = "60s"
  per_series_aligner = "ALIGN_RATE"
  alert_email        = var.alert_email

  depends_on = [time_sleep.resman_wait_10_seconds]
}