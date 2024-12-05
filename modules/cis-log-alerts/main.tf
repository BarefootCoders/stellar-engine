locals {
  alert_filters = {
    project-owner-log     = "metric.type=\"logging.googleapis.com/user/project-owner-log\" AND resource.type=\"global\""
    audit-config-change   = "metric.type=\"logging.googleapis.com/user/audit-config-change\" AND resource.type=\"global\""
    custom-role-change    = "metric.type=\"logging.googleapis.com/user/custom-role-change\" AND resource.type=\"global\""
    vpc-firewall-change   = "metric.type=\"logging.googleapis.com/user/vpc-firewall-change\" AND resource.type=\"global\""
    vpc-route-change      = "metric.type=\"logging.googleapis.com/user/vpc-route-change\" AND resource.type=\"global\""
    vpc-networking-change = "metric.type=\"logging.googleapis.com/user/vpc-network-change\" AND resource.type=\"gce_network\""
    storage-iam-change    = "metric.type=\"logging.googleapis.com/user/storage-iam-change\" AND resource.type=\"gcs_bucket\""
    sql-config-change     = "metric.type=\"logging.googleapis.com/user/sql-config-change\" AND resource.type=\"global\""
  }
}

resource "google_monitoring_notification_channel" "email" {
  project      = var.project
  display_name = "Log Alert Email"
  type         = "email"
  labels = {
    email_address = var.alert_email
  }
}

resource "google_monitoring_alert_policy" "alert_policy" {
  for_each = local.alert_filters
  project  = var.project

  # notification_channels = var.notification_channels
  notification_channels = [google_monitoring_notification_channel.email.name]
  display_name          = each.key
  combiner              = var.combiner
  conditions {
    display_name = "each.key"
    condition_threshold {
      filter     = each.value
      duration   = var.duration
      comparison = var.comparison
      aggregations {
        alignment_period   = var.alignment_period
        per_series_aligner = var.per_series_aligner
      }
    }
  }
}