resource "google_project_iam_binding" "bindings" {
  for_each = var.iam
  project  = var.project
  role     = each.key
  members  = each.value
}