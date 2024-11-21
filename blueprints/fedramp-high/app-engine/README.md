# Note
App Engine applications cannot be deleted once they're created; you have to delete the entire project to delete the application. Terraform will report the application has been successfully deleted; this is a limitation of Terraform, and will go away in the future. Terraform is not able to delete App Engine applications. https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/app_engine_application

<!-- BEGIN TOC -->
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [location_id](variables.tf#L1) | Region to create your App Engine resource. | <code>string</code> | ✓ |  |
| [project](variables.tf#L6) | Project to host app engine. App engine cannot be delete from the project once provisioned. | <code>string</code> | ✓ |  |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [app_id](outputs.tf#L1) | Identifier of the app. |  |
| [code_bucket](outputs.tf#L6) | GCS bucket where the app code is stored. |  |
| [default_bucket](outputs.tf#L11) | GCS bucket where the app content is stored. |  |
| [default_hostname](outputs.tf#L16) | Default hostname for the app. |  |
| [gcr_domain](outputs.tf#L21) | GCR domain used for storing managed Docker images. |  |
| [id](outputs.tf#L26) | An identifier for the resource. |  |
| [name](outputs.tf#L31) | Unique name of the app. |  |
<!-- END TFDOC -->
