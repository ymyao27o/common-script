data "alicloud_zones" "default" {
  available_resource_creation = "VSwitch"
}

resource "alicloud_vpc" "vpc" {
  vpc_name   = "vpc_1"
  cidr_block = "172.16.0.0/16"
}

resource "alicloud_vswitch" "vsw_1" {
  vpc_id       = alicloud_vpc.vpc.id
  vswitch_name = "vsw_aliyun_1"
  cidr_block   = "172.16.0.0/24"
  zone_id      = data.alicloud_zones.default.zones[0].id
}