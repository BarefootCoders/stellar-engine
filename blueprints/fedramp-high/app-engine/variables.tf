variable "location_id" {
  description = "Region to create your App Engine resource."
  type        = string
}

variable "project" {
  description = "Project to host app engine. App engine cannot be delete from the project once provisioned."
  type        = string
}
