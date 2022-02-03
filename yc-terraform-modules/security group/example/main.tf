module "sg" {
  source                    = "../"
  for_each                  = var.security_groups
  name                      = each.key
  vpc_id                    = var.vpc_id
  self                      = lookup(each.value, "self", false)
  ingress_rules_with_cidrs  = lookup(each.value, "ingress_rules_with_cidrs", [])
  ingress_rules_with_sg_ids = lookup(each.value, "ingress_rules_with_sg_ids", [])
  egress_rules              = lookup(each.value, "egress_rules", [])
}
output "ids" {
  value = module.sg
}
