output "workspace" {
  value = terraform.workspace
}

output "public_id" {
  value = module.ecs.public_ip
}

output "vswitchids" {
  value = module.vpc.vswitch_id
}

output "vswitchzoneids" {
  value = module.vpc.vswitch_zone_id
}
