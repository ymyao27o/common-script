variable "vsw_num" {
  type    = number
  default = 1

  validation {
    condition     = var.vsw_num < 256
    error_message = "vsw limit count 255"
  }
}

variable "ip_address" {
  description = "The input IP address"
  type        = string
  default     = "192.168.0.0"
}