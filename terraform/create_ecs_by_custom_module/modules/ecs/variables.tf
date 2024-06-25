variable "nsgid" {
  type = list(string)
}

variable "vswitchids" {
  type = list(string)
}

variable "vswitchzoneids" {
  type = list(string)
}

variable "instance_num" {
  type    = number
  default = 1
}