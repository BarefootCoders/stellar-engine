resource "google_org_policy_policy" "allow_external_lb" {
  name   = "projects/${data.google_project.project.number}/policies/compute.restrictLoadBalancerCreationForTypes"
  parent = "projects/${data.google_project.project.number}"
  spec {
    inherit_from_parent = true

    rules {
      values {
        allowed_values = ["EXTERNAL_MANAGED_HTTP_HTTPS"]
      }
    }
  }
}
