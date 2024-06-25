resource "random_id" "vpc_suffix" {
  byte_length = 8
}

resource "alicloud_vpc" "vpc" {
  vpc_name   = "vpc_${random_id.vpc_suffix.hex}"
  cidr_block = "${local.complete_ip_address}/16"
}

data "alicloud_zones" "default" {
  available_resource_creation = "VSwitch"
}

resource "alicloud_vswitch" "vsw" {
  vpc_id = alicloud_vpc.vpc.id

  // 循环随机取zoneid暂时无法实现，循环出的随机结果会变成[know after apply]无法立即作为索引
  count        = var.vsw_num
  vswitch_name = format("vsw_%02d", count.index + 1)
  zone_id      = element(data.alicloud_zones.default.zones.*.id, count.index % var.vsw_num)
  cidr_block   = "${join(".", [local.padded_ip_parts[0], local.padded_ip_parts[1], "${count.index}", local.padded_ip_parts[3]])}/24"
}