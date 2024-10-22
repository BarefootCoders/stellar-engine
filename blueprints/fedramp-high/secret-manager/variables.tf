variable "project_id" {
  description = "The Project ID where the secrets will be created."
  type        = string
}

variable "region" {
  description = "The Google Cloud region."
  type        = string
  default     = "us-east4"
}

variable "zone" {
  description = "The Google Cloud zone within the specified region."
  type        = string
  default     = "us-east4-a"
}

variable "secrets" {
  description = "Map of secrets to manage, their locations and KMS keys in {LOCATION => KEY} format."
  type = map(object({
    locations = (list(string))  #A list of locations is required for every secret
    keys      = (map(string))   #A key is required for every location (the key and secret must be in the same region)
  }))
  default = {}
}

variable "iam" {
  description = "IAM bindings in {SECRET => {ROLE => [MEMBERS]}} format."
  type        = map(map(list(string)))
  default     = {}
}

variable "versions" {
  description = "Optional versions to manage for each secret. Version names are only used internally to track individual versions."
  type = map(map(object({
    enabled = bool
    data    = string #Setting this value in a local terraform file is not recommended for security reasons
    #For more information visit: https://developer.hashicorp.com/terraform/language/state/sensitive-data
  })))
  default = {}
}