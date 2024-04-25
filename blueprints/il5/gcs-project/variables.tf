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

variable "autoclass" {
  description = "Enable autoclass to automatically transition objects to appropriate storage classes based on their access pattern. If set to true, storage_class must be set to STANDARD. When set to true, All objects added to the bucket begin in Standard storage, even if a different storage class is specified in the request. Defaults to set to True"
  type        = bool
  #default     = false
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
  default     = "EU"
  # Set to us-east4 or us-cental1
}
 
variable "name" {
  description = "Bucket name suffix."
  type        = string
}
 
variable "prefix" {
  description = "Optional prefix used to generate the bucket name."
  type        = string
  default     = null
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty, please use null instead."
  }
}

variable "project_id" {
  description = "Bucket project id."
  type        = string
}


variable "storage_class" {
  description = "Bucket storage class."
  type        = string
  default     = "MULTI_REGIONAL"
  validation {
    condition     = contains(["STANDARD", "MULTI_REGIONAL", "REGIONAL", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "Storage class must be one of STANDARD, MULTI_REGIONAL, REGIONAL, NEARLINE, COLDLINE, ARCHIVE."
  }
}
 