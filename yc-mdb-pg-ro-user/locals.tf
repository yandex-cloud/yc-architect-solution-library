locals {
  folder_id = var.folder_id
  vpc_id = var.create_vpc ? yandex_vpc_network.this[0].id : var.vpc_id
  subnet_id = var.create_subnet ? yandex_vpc_subnet.subnet[0].id : var.subnet_id
  sg_id = var.create_sg ? [yandex_vpc_security_group.security_group[0].id] : [var.sg_id]
}
