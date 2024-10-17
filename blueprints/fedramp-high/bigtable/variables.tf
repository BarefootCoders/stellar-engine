variable "project_id" {
  description = "The project ID to deploy Bigtable to."
  type        = string
}

variable "region" {
  description = "The Google Cloud region."
  type        = string
  default     = "us-east4"
}

variable "zone" {
  description = "The Google Cloud zone."
  type        = string
  default     = "us-east4-a"
}

variable "instance_name" {
  description = "The Bigtable instance name."
  type        = string
}

variable "cluster_id" {
  description = "The Bigtable cluster ID."
  type        = string
}

variable "num_nodes" {
  description = "Number of nodes in the Bigtable cluster."
  type        = number
  default     = 1
}

variable "key_name" {
  description = "The name of the existing key (required if use_existing_keys is true)."
  type        = string
  default = null
}

variable "storage_type" {
  description = "Either SSD or HDD."
  type        = string
  default     = "SSD"
}

variable "deletion_protection" {
  description = "Permission to delete instance via terraform."
  type        = bool
  default     = true
}

variable "table" {
  description = "Table to create in the bigtable instance. Default is null."
  type = map(object({
    split_keys      = optional(list(string))
    column_families = map(object({}))
  }))
  default = {
    "Test" = {
      column_families = {}
    }
  }
}
