data "google_storage_bucket" "terraform_state" {
  name = var.terraform_state_bucket != null ? var.terraform_state_bucket : "${var.prefix}-gemini-enterprise-tf-state-${var.main_project_id}"
}
