#创建ECS实例
resource "alicloud_instance" "instance" {
  instance_type              = "ecs.e-c1m1.large"
  image_id                   = "aliyun_3_9_x64_20G_alibase_20231219.vhd"
  system_disk_category       = "cloud_essd"
  instance_name              = "instance-01"
  password                   = "admin@1024"
  internet_max_bandwidth_out = 1
  security_groups            = var.nsgid
  vswitch_id                 = var.vswitchid
  availability_zone          = var.vswitchzoneid
}