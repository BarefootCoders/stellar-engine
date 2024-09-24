
resource "google_project_service" "project_service" {
  project = var.project
  service = "iap.googleapis.com"
}

resource "google_iap_client" "project_client" {
  display_name = "CNAP Client"
  brand        = "projects/${data.google_project.project.number}/brands/${var.oauth_brand_number}"
}

resource "google_iap_web_region_backend_service_iam_binding" "binding" {
  for_each                   = local.apps
  project                    = var.project
  web_region_backend_service = module.cnap-0.backend_service_names[each.key]
  role                       = "roles/iap.httpsResourceAccessor"
  members                    = each.value.members

  condition {
    title       = lookup(each.value, "condition", { "title" = "" }).title
    description = lookup(each.value, "condition", { "description" = "" }).description
    expression  = lookup(each.value, "condition", { "expression" = "" }).expression
  }
}

resource "google_project_service_identity" "iap_sa" {
  provider = google-beta

  project = var.project
  service = "iap.googleapis.com"
}

resource "google_project_iam_member" "iap_sa_cloudrun_invoker" {
  project = var.project
  role    = "roles/run.invoker"
  member  = google_project_service_identity.iap_sa.member
}