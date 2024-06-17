output "vpc_id" {
  value = alicloud_vpc.vpc.id
}

output "vswitch_id" {
  value = alicloud_vswitch.vsw_1.id
}

output "vswitch_zone_id" {
  value = alicloud_vswitch.vsw_1.zone_id
}
