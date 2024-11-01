locals {
  file = yamldecode(file(var.rules_file))

  policies = {
    for policy_name, policy_data in local.file :
    policy_name => {
      region      = try(policy_data.region, null)
      description = try(policy_data.description, null)
      project     = try(policy_data.project, null)
    }
  }

  rules = flatten([
    for policy_name, data in local.file : [
      for rule in data.rules :
      merge(
        rule,
        {
          policy                 = policy_name,
          region                 = (local.policies[policy_name].region == null ? var.region : local.policies[policy_name].region),
          default_action         = try(data.default_action, null),
          default_versioned_expr = try(data.default_versioned_expr, null),
          default_src_ip_ranges  = try(data.default_src_ip_ranges, null)
        }
      )
    ]
  ])
}

resource "google_compute_region_security_policy" "policy" {
  provider = google-beta
  for_each = local.policies

  name        = each.key
  project     = each.value.project
  region      = each.value.region
  description = each.value.description
  type        = "CLOUD_ARMOR"
}

resource "google_compute_region_security_policy_rule" "policy_rule" {
  provider   = google-beta
  for_each   = { for i, rule in local.rules : i => rule }
  depends_on = [google_compute_region_security_policy.policy]

  security_policy = each.value.policy
  region          = each.value.region
  priority        = each.value.priority
  action          = try(each.value.action, each.value.default_action)

  preview     = try(each.value.preview, null)
  description = try(each.value.description, null)

  match {
    dynamic "expr" {
      for_each = try(each.value.expression, null) != null ? [1] : []
      content {
        expression = "evaluatePreconfiguredWaf('${each.value.expression}')"
      }
    }

    versioned_expr = try(each.value.expression, null) != null ? null : try(each.value.versioned_expr, each.value.default_versioned_expr)
    dynamic "config" {
      for_each = try(each.value.expression, null) != null ? [] : [1] //only create a config block if there isn't an expr block
      content {
        src_ip_ranges = try(each.value.src_ip_ranges, try(each.value.default_src_ip_ranges, null))
      }
    }
  }

  dynamic "preconfigured_waf_config" {
    for_each = try(each.value.preconfigured_waf_config, []) // == null ? [] : each.value.preconfigured_waf_config
    content {
      dynamic "exclusion" {
        for_each = try(preconfigured_waf_config.value.exclusion, [])
        content {
          dynamic "request_header" {
            for_each = try(exclusion.value.request_header, []) // == null ? [] : exclusion.value.request_header
            content {
              operator = request_header.value.operator
              value    = try(request_header.value.value, null)
            }
          }
          dynamic "request_cookie" {
            for_each = try(exclusion.value.request_cookie, []) // == null ? [] : exclusion.value.request_cookie
            content {
              operator = request_cookie.value.operator
              value    = try(request_cookie.value.value, null)
            }
          }
          dynamic "request_uri" {
            for_each = try(exclusion.value.request_uri, []) //== null ? [] : exclusion.value.request_uri
            content {
              operator = request_uri.value.operator
              value    = try(request_uri.value.value, null)
            }
          }
          dynamic "request_query_param" {
            for_each = try(exclusion.value.request_query_param, []) // == null ? [] : exclusion.value.request_query_param
            content {
              operator = request_query_param.value.operator
              value    = try(request_query_param.value.value, null)
            }
          }
          target_rule_set = try(exclusion.value.target_rule_set, null)
          target_rule_ids = try(exclusion.value.target_rule_ids, null)
        }
      }
    }
  }

  dynamic "rate_limit_options" {
    for_each = try(each.value.rate_limit_options, null) == null ? [] : [each.value.rate_limit_options]
    content {
      dynamic "rate_limit_threshold" {
        for_each = try(rate_limit_options.value.rate_limit_threshold, null) == null ? [] : [rate_limit_options.value.rate_limit_threshold]
        content {
          count        = try(rate_limit_threshold.value.count, null)
          interval_sec = try(rate_limit_threshold.value.interval_sec, null)
        }
      }
      conform_action = try(rate_limit_options.value.conform_action, null)
      exceed_action  = try(rate_limit_options.value.exceed_action, null)
      dynamic "enforce_on_key_configs" {
        for_each = try(rate_limit_options.value.enforce_on_key_configs, null) == null ? [] : rate_limit_options.value.enforce_on_key_configs
        content {
          enforce_on_key_type = try(enforce_on_key_configs.value.enforce_on_key_type, null)
          enforce_on_key_name = try(enforce_on_key_configs.value.enforce_on_key_name, null)
        }
      }
      dynamic "ban_threshold" {
        for_each = try(rate_limit_options.value.ban_threshold, null) == null ? [] : [rate_limit_options.value.ban_threshold]
        content {
          count        = try(ban_threshold.value.count, null)
          interval_sec = try(ban_threshold.value.interval_sec, null)
        }
      }
      ban_duration_sec = try(rate_limit_options.value.ban_duration_sec, null)
    }
  }
}