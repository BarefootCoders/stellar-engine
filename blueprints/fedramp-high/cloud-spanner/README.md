

<!-- BEGIN TOC -->
- [Outputs](#outputs)
<!-- END TOC -->
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [database_name](variables.tf#L8) | Database name. | <code>string</code> | ✓ |  |
| [database_user](variables.tf#L13) | Database user or group. Must start with \"user:\" or \"group:\" or \"serviceAccount:\". | <code>string</code> | ✓ |  |
| [display_name](variables.tf#L18) | Cloud spanner display name. | <code>string</code> | ✓ |  |
| [instance_name](variables.tf#L29) | Cloud spanner instance name. | <code>string</code> | ✓ |  |
| [project](variables.tf#L52) | Project to deploy Cloud Spanner instance. | <code>string</code> | ✓ |  |
| [config_name](variables.tf#L2) | Cloud spanner instance config name. | <code>string</code> |  | <code>&#34;regional-us-east4&#34;</code> |
| [high_priority_cpu_utilization_percent](variables.tf#L23) | High priority cpu utilization percent. | <code>number</code> |  | <code>75</code> |
| [location_id](variables.tf#L34) | Region to create your App Engine resource. | <code>string</code> |  | <code>&#34;us-east4&#34;</code> |
| [max_processing_units](variables.tf#L40) | Max processing units for autoscaling. | <code>number</code> |  | <code>3000</code> |
| [min_processing_units](variables.tf#L46) | Min processing units for autoscaling. | <code>number</code> |  | <code>2000</code> |
| [storage_utilization_percent](variables.tf#L57) | Storage utilization percent. | <code>number</code> |  | <code>90</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [instance](outputs.tf#L1) | Cloud spanner instance. |  |
<!-- END TFDOC -->
