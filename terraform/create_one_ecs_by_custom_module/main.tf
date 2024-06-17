module "vpc" {
  source = "./modules/vpc"
}

module "nsg" {
  source = "./modules/nsg"
  vpcid  = module.vpc.vpc_id
}

module "ecs" {
  source        = "./modules/ecs"
  nsgid         = module.nsg.nsg_id
  vswitchid     = module.vpc.vswitch_id
  vswitchzoneid = module.vpc.vswitch_zone_id
}