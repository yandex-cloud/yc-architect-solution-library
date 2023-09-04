
resource "yandex_vpc_security_group" "securtiy_group_master" {
  count       = var.security_group_create ? 1 : 0
  name        = "${var.network_name}-manager"
  description = "${var.network_name}'s security group for master"
  network_id  = local.network_id
  folder_id   = var.folder_id

  ingress {
    protocol       = "ICMP"
    description    = "icmp"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "ssh"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  egress {
    protocol       = "ANY"
    description    = "Allow any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "security_group_worker" {
  count       = var.security_group_create ? 1 : 0
  name        = "${var.network_name}-worker"
  description = "${var.network_name}'s security group for docker-machine master"
  network_id  = local.network_id
  folder_id   = var.folder_id

  ingress {
    protocol       = "ICMP"
    description    = "icmp"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol          = "TCP"
    description       = "ssh"
    security_group_id = yandex_vpc_security_group.securtiy_group_master[0].id
    port              = 22
  }

  ingress {
    protocol          = "TCP"
    description       = "docker"
    security_group_id = yandex_vpc_security_group.securtiy_group_master[0].id
    port              = 2376
  }

  egress {
    protocol       = "ANY"
    description    = "Allow any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

