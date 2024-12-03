variable "deletion_protection" {
  description = "Deletion proteciton."
  type        = bool
  default     = true
}

variable "file" {
  description = "File path of the yaml instructions for the workflow."
  type        = string
  default     = "code/example.yaml"
}

variable "project" {
  description = "The Google Project ID."
  type        = string
}

variable "region" {
  description = "The Google Cloud region."
  type        = string
}

variable "src_lang" {
  description = "The source language of the text."
  type        = string
  default     = "es"
}

variable "target_lang" {
  description = "The target language to translate into."
  type        = string
  default     = "en"
}