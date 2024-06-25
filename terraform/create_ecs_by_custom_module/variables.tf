variable "access_key" {
  type        = string
  description = "aliyun cloud access key"
}

variable "secret_key" {
  type        = string
  description = "aliyun cloud secret key"
}

variable "region" {
  type        = string
  default     = "cn-huhehaote"
  description = "this is a variable REGION, which define a region of resource"
  sensitive   = false
  validation {
    condition     = can(regex("^cn-", var.region))
    error_message = "The region must be starting with \"cn-\"."
  }
}