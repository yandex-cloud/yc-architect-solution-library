### Network
resource "yandex_vpc_network" "this" {
  count = var.create_vpc ? 1 : 0
  description = "VPC for demo postgresql ro user"
  name = "vpc-demo-pg-ro-user"
  folder_id = local.folder_id
}

resource "yandex_vpc_subnet" "subnet" {
  count = var.create_subnet ? 1 : 0
  name = "subnet-demo-pg-ro-user"
  description = "Subnet for demo postgresql ro user"
  v4_cidr_blocks = [var.subnet_v4_cidr_block]
  zone = var.default_zone
  network_id = local.vpc_id
  folder_id = local.folder_id
}

resource "yandex_vpc_security_group" "security_group" {
  count = var.create_sg ? 1 : 0
  name        = "securtiy-group-demo-pg-ro-user"
  description = "Securtiy group for demo postgresql ro user"
  folder_id = local.folder_id
  network_id  = local.vpc_id

  ingress {
    protocol       = "ICMP"
    description    = "icmp"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "postgresql"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 6432
  }

  egress {
    protocol       = "ANY"
    description    = "Allow any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
