#创建ECS实例
resource "alicloud_instance" "instance" {
  instance_type        = local.instance_type_list[count.index % length(local.instance_type_list)]
  image_id             = local.image_id_list[count.index % length(local.image_id_list)]
  system_disk_category = local.system_disk_category_list[count.index % length(local.system_disk_category_list)]
  password             = local.password_list[count.index % length(local.password_list)]

  internet_max_bandwidth_out = local.bandwidth_list[count.index % length(local.bandwidth_list)]
  security_groups            = var.nsgid
  vswitch_id                 = var.vswitchids[count.index % length(var.vswitchids)]
  availability_zone          = var.vswitchzoneids[count.index % length(var.vswitchzoneids)]

  # count 属于内置属性，类似迭代器标识迭代次数后将会执行[0,count)次，适用资源属性存在大部分相同的情况
  # https://developer.hashicorp.com/terraform/language/meta-arguments/count
  count         = var.instance_num
  instance_name = format("%s-%02d", local.instance_prefix, count.index + 1)
  host_name     = format("%s-%02d", local.instance_prefix, count.index + 1)
}