# Cloud Armor Blueprint
This blueprint demonstrates how to use Google Cloud Armor to create policies and rules that can be applied to backend services. These rules will monitor incoming traffic to ensure security.

## Introduction to Google Cloud Armor 
Google Cloud Armor helps you protect your Google Cloud deployments from multiple types of threats, including distributed denial-of-service (DDoS) attacks and application attacks like cross-site scripting (XSS) and SQL injection (SQLi). Google Cloud Armor features some automatic protections and some that you need to configure manually.

## Disclaimer
- The present GCP Terraform Module in this project is set up and intended to be implemented in a FEDRAMP High environment using the Assured Workdloads within the Google Cloud Platform (GCP) organization.
<!-- BEGIN_TF_DOCS -->
## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_policies"></a> [policies](#input\_policies) | Map of policies to manage. | <pre>map(object({ # map the name of the policy to the data<br/>        region = optional(string)<br/>        project = optional(string)<br/>        description = optional(string)<br/>    }))</pre> | `{}` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID for the project that the Cloud Armor policies will be used in. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The Google Cloud region. | `string` | `"us-east4"` | no |
| <a name="input_rules"></a> [rules](#input\_rules) | Map of policy rules to manage. Each rule should be assigned to an existing policy. | <pre>list(object({ <br/>        project = optional(string, null)<br/>        description = optional(string, null)<br/>        policy = string               # name of the policy that this rule is applied to<br/>        region = string<br/>        priority = number             # 0 is the highest priority and 2147483647 is the lowest priority<br/>        action = string               # allow, deny(STATUS), rate_based_ban, redirect, throttle<br/>        preview = optional(bool)      # If set to true, the specified action is not enforced.<br/><br/>        match = object({<br/>            versioned_expr = optional(string, null)<br/>            expr = optional(object({<br/>                expression = string<br/>            }))<br/>            config = optional(object({ <br/>                src_ip_ranges = optional(list(string)) # Maximum number of srcIpRanges allowed is 10.<br/>            }))<br/>        })<br/><br/>        preconfigured_waf_config = optional(list(object({<br/>            exclusion = optional(list(object({<br/>                request_header = optional(list(object({<br/>                    operator = string<br/>                    value    = optional(string)<br/>                })))<br/>                request_cookie = optional(list(object({<br/>                    operator = string<br/>                    value    = optional(string)<br/>                })))<br/>                request_uri = optional(list(object({<br/>                    operator = string<br/>                    value    = optional(string)<br/>                })))<br/>                request_query_param = optional(list(object({<br/>                    operator = string<br/>                    value    = optional(string)<br/>                })))<br/>                target_rule_set = string<br/>                target_rule_ids = optional(list(string))<br/>            })))<br/>        })))<br/><br/>        rate_limit_options = optional(object({ # Must be specified if the action is "rate_based_ban" or "throttle"<br/>            rate_limit_threshold = optional(object({ <br/>                count = optional(number) <br/>                interval_sec = optional(number) #must be one of 10, 30, 60, 120, 180, 240, 300, 600, 900, 1200, 1800, 2700, 3600<br/>            }))<br/>            conform_action = optional(string) # Only option is "allow"<br/>            exceed_action = optional(string) # Only option is "deny(STATUS)"<br/>            enforce_on_key_configs = optional(list(object({ # You can specify up to 3 enforceOnKeyConfigs<br/>                enforce_on_key_type = optional(string) # Possible values: ALL, IP, HTTP_HEADER, XFF_IP, HTTP_COOKIE, HTTP_PATH, SNI, REGION_CODE, TLS_JA3_FINGERPRINT, USER_IP<br/>                enforce_on_key_name = optional(string) # Rate limit key name, only applicable for: HTTP_HEADER, HTTP_COOKIE<br/>            })))<br/>            ban_threshold = optional(object({ # Can only be specified if the action for the rule is "rate_based_ban"<br/>                count = optional(number) <br/>                interval_sec = optional(number)<br/>            }))<br/>            ban_duration_sec = optional(number) <br/>        }))<br/>    }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_policies"></a> [policies](#output\_policies) | All created policy resources. |
| <a name="output_policy_names"></a> [policy\_names](#output\_policy\_names) | All created policy names. |
| <a name="output_policy_rules"></a> [policy\_rules](#output\_policy\_rules) | All created policy rule resources. |
<!-- END_TF_DOCS -->
## Deployment Steps

You should see this README and some terraform files in the directory. 
1. Copy the contents of the terraform.tfvars.sample file into your own terraform.tfvars file, then update the variables in this file. For reference update the following variables and associated properties:

- ```project_id```  with your GCP Project ID <br />
- ```region``` with the GCP Location <br />
- ```policies``` with the desired policies to be created, as well as the region they will be used in <br />
-  ```rules```  with the desired rules assigned to each policy <br />

2. The usual terraform commands will be used to deploy the policies. To provision this example, run the following from within this directory:

```terraform init ```<br />
```terraform plan``` to see the infrastructure plan<br />
```terraform apply``` to apply the infrastructure build<br />
```terraform destroy``` only if you wish to destroy the built infrastructure<br />

Verification of a successful deployment? 
All of the policies will be created and available through the Cloud Console. They will be located under Network Security in the Cloud Armor policies tab (or you can just search "cloud armor" in the console). Upon clicking on each policy, you should see each associated rule that has been assigned to the policy. From here you can apply each of these policies to existing resources, or apply them to new resources when they are created. 

To apply these policies to existing resources:

1. Click on the policy name to see the Policy Details page.
2. Click on the Targets tab to see which targets the policy is applied to.
3. Click "Apply Policy to New Target" to add this policy to targets of your choosing.

## Troubleshooting
Many of the options in the rules variable have requirements that must be followed.
A few examples are:
- If you specify the action as "rate_based_ban" or "throttle", you must create a rate_limit_options block.
- When choosing the interval time in "rate_limit_threshold", you can only select 10, 30, 60, 120, 180, 240, 300, 600, 900, 1200, 1800, 2700, or 3600 seconds.
- The only accepted value for "versioned_expr" in the match block is "SRC_IPS_V1".
- When selecting "deny(STATUS)" for the "action", STATUS must be 403, 404, 429, or 502.