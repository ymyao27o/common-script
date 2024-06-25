locals {
  instance_prefix           = "instance"
  instance_type_list        = ["ecs.e-c1m1.large"]
  image_id_list             = ["aliyun_3_9_x64_20G_alibase_20231219.vhd"]
  system_disk_category_list = ["cloud_essd"]
  password_list             = ["admin@1024"]
  bandwidth_list            = [1, 0, 0]
}