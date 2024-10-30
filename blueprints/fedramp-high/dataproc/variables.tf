variable "project_id" {
  type         = string
  description  = "The project name"
}

variable "account_id" {
  type         = string
  description  = "The account id for the service account"
}

variable "region" {
  type         = string
  description  = "The region"
}

variable "labels" {
  type         = map(string)
  description  = "Set of labels to identify the cluster"
  default      = {}
}

variable "cluster_name" {
  type         = string
  description  = "The name of the DataProc cluster to be created"
}

variable "network" {
  type         = string
  description  = "VPC network"
}

variable "zone" {
  type         = string
  description  = "GCP zone"
  default      = "us-east4-c"
}

variable "subnet" {
  type         = string
  description  = "Subnet for VPC"
}

variable "kms_key" {
  type         = string
}
