/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable "name" {
  description = "Bucket name suffix."
  type        = string
  default     = "tapanapr29v2"
}

variable "prefix" {
  description = "Optional prefix used to generate the bucket name."
  type        = string
  default     = "tnbgcp"
}

variable "project_create" {
  description = "Parameters for the creation of a new project."
  type = object({
    billing_account_id = string
    parent             = string
  })
  default = null
}

# Project number: 53935569403
# Project ID: tapan-dev 

variable "project_id" {
  description = "Project ID."
  type        = string
  default     = "tapan-dev"
}

variable "autoclass" {
  description = "For IL5 Requirements, Enable the autoclass to True. If set to true, storage_class must be set to STANDARD. When set to true, All objects added to the bucket begin in Standard storage, even if a different storage class is specified in the request."
  type        = bool
  default     = true
}

variable "public_access_prevention" {
  description = "Prevents public access to a bucket. The default value is set to enforced and enabled with private access only. Enabling public access prevention. Acceptable values are inherited or enforced. If inherited, the bucket uses public access prevention, only if the bucket is subject to the public access prevention organization policy constraint."
  type        = string
  default     = "enforced"
}


variable "location" {
  description = "Bucket location."
  type        = string
  default     = "us-east4"
  # Set to us-east4 or us-cental1
}


variable "storage_class" {
  description = "Bucket storage class."
  type        = string
  default     = "STANDARD"
  # Is AutoClass is Enabled the Storage Class Shall be set to Standard
}

variable "versioning" {
  description = "The IL5 requires,  versioning Enabled to true"
  type        = bool
  default     = true
}