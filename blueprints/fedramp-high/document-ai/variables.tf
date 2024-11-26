variable "file" {
  description = "File path of the yaml instructions for the workflow."
  type        = string
  default     = "code/example.yaml"
}

variable "name" {
  description = "Name of the Document AI processor."
  type        = string
}

variable "project" {
  description = "The Google Project ID."
  type        = string
}

variable "region" {
  description = "The Google Cloud region."
  type        = string
}

variable "type" {
  description = "Type of Document AI model."
  type        = string
  default     = "OCR_PROCESSOR"
}