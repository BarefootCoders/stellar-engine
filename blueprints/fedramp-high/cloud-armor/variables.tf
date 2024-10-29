variable "project_id" {
  description = "The ID for the project that the Cloud Armor policies will be used in."
  type        = string
}

variable "region" {
  description = "The Google Cloud region."
  type        = string
  default     = "us-east4"
}

variable "policies" {
  description = "Map of policies to manage."
  type = map(object({ # map the name of the policy to the data
    region      = optional(string)
    project     = optional(string)
    description = optional(string)
  }))
  default = {}
}

variable "rules" {
  description = "Map of policy rules to manage. Each rule should be assigned to an existing policy."
  type = list(object({
    project     = optional(string, null)
    description = optional(string, null)
    policy      = string # name of the policy that this rule is applied to
    region      = string
    priority    = number         # 0 is the highest priority and 2147483647 is the lowest priority
    action      = string         # allow, deny(STATUS), rate_based_ban, redirect, throttle
    preview     = optional(bool) # If set to true, the specified action is not enforced.

    match = object({
      versioned_expr = optional(string, null)
      expr = optional(object({
        expression = string
      }))
      config = optional(object({
        src_ip_ranges = optional(list(string)) # Maximum number of srcIpRanges allowed is 10.
      }))
    })

    preconfigured_waf_config = optional(list(object({
      exclusion = optional(list(object({
        request_header = optional(list(object({
          operator = string
          value    = optional(string)
        })))
        request_cookie = optional(list(object({
          operator = string
          value    = optional(string)
        })))
        request_uri = optional(list(object({
          operator = string
          value    = optional(string)
        })))
        request_query_param = optional(list(object({
          operator = string
          value    = optional(string)
        })))
        target_rule_set = string
        target_rule_ids = optional(list(string))
      })))
    })))

    rate_limit_options = optional(object({ # Must be specified if the action is "rate_based_ban" or "throttle"
      rate_limit_threshold = optional(object({
        count        = optional(number)
        interval_sec = optional(number) #must be one of 10, 30, 60, 120, 180, 240, 300, 600, 900, 1200, 1800, 2700, 3600
      }))
      conform_action = optional(string)               # Only option is "allow"
      exceed_action  = optional(string)               # Only option is "deny(STATUS)"
      enforce_on_key_configs = optional(list(object({ # You can specify up to 3 enforceOnKeyConfigs
        enforce_on_key_type = optional(string)        # Possible values: ALL, IP, HTTP_HEADER, XFF_IP, HTTP_COOKIE, HTTP_PATH, SNI, REGION_CODE, TLS_JA3_FINGERPRINT, USER_IP
        enforce_on_key_name = optional(string)        # Rate limit key name, only applicable for: HTTP_HEADER, HTTP_COOKIE
      })))
      ban_threshold = optional(object({ # Can only be specified if the action for the rule is "rate_based_ban"
        count        = optional(number)
        interval_sec = optional(number)
      }))
      ban_duration_sec = optional(number)
    }))
  }))
  default = []
}
