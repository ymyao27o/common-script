module "vpc" {
  source  = "./modules/vpc"
  vsw_num = 2
}

module "nsg" {
  source = "./modules/nsg"
  vpcid  = module.vpc.vpc_id
}

module "ecs" {
  source         = "./modules/ecs"
  nsgid          = module.nsg.nsg_id
  vswitchids     = module.vpc.vswitch_id
  vswitchzoneids = module.vpc.vswitch_zone_id
  instance_num   = 3
}