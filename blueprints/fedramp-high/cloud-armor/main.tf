resource "google_compute_region_security_policy" "policy" {
  provider = google-beta
  for_each = var.policies

  name        = each.key
  project     = each.value.project
  region      = each.value.region
  description = each.value.description
  type        = "CLOUD_ARMOR"
}

resource "google_compute_region_security_policy_rule" "policy_rule" {
  provider   = google-beta
  for_each   = { for i, rule in var.rules : i => rule }
  depends_on = [google_compute_region_security_policy.policy]

  security_policy = each.value.policy
  region          = each.value.region
  priority        = each.value.priority
  action          = each.value.action

  description = each.value.description
  project     = each.value.project

  dynamic "match" {
    for_each = each.value.match == null ? [] : [each.value.match]
    content {
      versioned_expr = match.value.versioned_expr
      dynamic "expr" {
        for_each = match.value.expr == null ? [] : [match.value.expr]
        content {
          expression = expr.value.expression
        }
      }
      dynamic "config" {
        for_each = match.value.config == null ? [] : [match.value.config]
        content {
          src_ip_ranges = config.value.src_ip_ranges
        }
      }
    }
  }

  dynamic "preconfigured_waf_config" {
    for_each = each.value.preconfigured_waf_config == null ? [] : each.value.preconfigured_waf_config
    content {
      dynamic "exclusion" {
        for_each = preconfigured_waf_config.value.exclusion
        content {
          dynamic "request_header" {
            for_each = exclusion.value.request_header == null ? [] : exclusion.value.request_header
            content {
              operator = request_header.value.operator
              value    = request_header.value.value
            }
          }
          dynamic "request_cookie" {
            for_each = exclusion.value.request_cookie == null ? [] : exclusion.value.request_cookie
            content {
              operator = request_cookie.value.operator
              value    = request_cookie.value.value
            }
          }
          dynamic "request_uri" {
            for_each = exclusion.value.request_uri == null ? [] : exclusion.value.request_uri
            content {
              operator = request_uri.value.operator
              value    = request_uri.value.value
            }
          }
          dynamic "request_query_param" {
            for_each = exclusion.value.request_query_param == null ? [] : exclusion.value.request_query_param
            content {
              operator = request_query_param.value.operator
              value    = request_query_param.value.value
            }
          }
          target_rule_set = exclusion.value.target_rule_set
          target_rule_ids = exclusion.value.target_rule_ids
        }
      }
    }
  }

  dynamic "rate_limit_options" {
    for_each = each.value.rate_limit_options == null ? [] : [each.value.rate_limit_options]
    content {
      dynamic "rate_limit_threshold" {
        for_each = rate_limit_options.value.rate_limit_threshold == null ? [] : [rate_limit_options.value.rate_limit_threshold]
        content {
          count        = rate_limit_threshold.value.count
          interval_sec = rate_limit_threshold.value.interval_sec
        }
      }
      conform_action = rate_limit_options.value.conform_action
      exceed_action  = rate_limit_options.value.exceed_action
      dynamic "enforce_on_key_configs" {
        for_each = rate_limit_options.value.enforce_on_key_configs == null ? [] : rate_limit_options.value.enforce_on_key_configs
        content {
          enforce_on_key_type = enforce_on_key_configs.value.enforce_on_key_type
          enforce_on_key_name = enforce_on_key_configs.value.enforce_on_key_name
        }
      }
      dynamic "ban_threshold" {
        for_each = rate_limit_options.value.ban_threshold == null ? [] : [rate_limit_options.value.ban_threshold]
        content {
          count        = ban_threshold.value.count
          interval_sec = ban_threshold.value.interval_sec
        }
      }
      ban_duration_sec = rate_limit_options.value.ban_duration_sec
    }
  }
}