output "nsg_id" {
  value = alicloud_security_group.default.*.id
}