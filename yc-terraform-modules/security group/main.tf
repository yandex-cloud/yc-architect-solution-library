### Datasource
data "yandex_client_config" "client" {}

### Locals
locals {
  folder_id = var.folder_id == null ? data.yandex_client_config.client.folder_id : var.folder_id
}

resource "yandex_vpc_security_group" "this" {
  description = "security group"
  name        = var.name
  network_id  = var.vpc_id
  labels      = var.labels
}
resource "yandex_vpc_security_group_rule" "ingress_rules_with_cidrs" {
  count                  = length(var.ingress_rules_with_cidrs)
  security_group_binding = yandex_vpc_security_group.this.id
  direction              = "ingress"
  description            = lookup(var.ingress_rules_with_cidrs[count.index], "description", "")
  v4_cidr_blocks         = lookup(var.ingress_rules_with_cidrs[count.index], "v4_cidr_blocks", [])
  port                   = lookup(var.ingress_rules_with_cidrs[count.index], "port", null)
  from_port              = lookup(var.ingress_rules_with_cidrs[count.index], "from_port", null)
  to_port                = lookup(var.ingress_rules_with_cidrs[count.index], "to_port", null)
  protocol               = lookup(var.ingress_rules_with_cidrs[count.index], "protocol", "ANY")
}
resource "yandex_vpc_security_group_rule" "ingress_rules_with_sg_ids" {
  count                  = length(var.ingress_rules_with_sg_ids)
  security_group_binding = yandex_vpc_security_group.this.id
  direction              = "ingress"
  description            = lookup(var.ingress_rules_with_sg_ids[count.index], "description", "")
  port                   = lookup(var.ingress_rules_with_sg_ids[count.index], "port", null)
  from_port              = lookup(var.ingress_rules_with_sg_ids[count.index], "from_port", null)
  to_port                = lookup(var.ingress_rules_with_sg_ids[count.index], "to_port", null)
  protocol               = lookup(var.ingress_rules_with_sg_ids[count.index], "protocol", "ANY")
  security_group_id      = lookup(var.ingress_rules_with_sg_ids[count.index], "security_group_id", null)
}
resource "yandex_vpc_security_group_rule" "ingress_self_rule" {
  count                  = var.self == true ? 1 : 0
  security_group_binding = yandex_vpc_security_group.this.id
  direction              = "ingress"
  description            = "Communication inside this SG"
  port                   = var.self_port
  from_port              = var.self_from_port
  to_port                = var.self_to_port
  protocol               = var.self_protocol
  predefined_target      = "self_security_group"
}
resource "yandex_vpc_security_group_rule" "egress_rules" {
  count                  = length(var.egress_rules)
  security_group_binding = yandex_vpc_security_group.this.id
  direction              = "egress"
  description            = lookup(var.egress_rules[count.index], "description", "")
  v4_cidr_blocks         = lookup(var.egress_rules[count.index], "v4_cidr_blocks", ["0.0.0.0/0"])
  port                   = lookup(var.egress_rules[count.index], "port", null)
  from_port              = lookup(var.egress_rules[count.index], "from_port", 0)
  to_port                = lookup(var.egress_rules[count.index], "to_port", 65535)
  protocol               = lookup(var.egress_rules[count.index], "protocol", "ANY")
}
