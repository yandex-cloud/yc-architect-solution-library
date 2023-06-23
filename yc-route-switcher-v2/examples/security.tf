// create security group for NAT-instances
resource "yandex_vpc_security_group" "nat_instance_sg" {
  name        = "public-sg"
  description = "Security group for NAT-instance"
  folder_id   = var.folder_id
  network_id  = yandex_vpc_network.vpc.id

  ingress {
    protocol            = "TCP"
    description         = "NLB healthcheck"
    port                = 22
    predefined_target   = "loadbalancer_healthchecks"
  }

  ingress {
    protocol            = "TCP"
    description         = "SSH from trusted public IP addresses"
    port                = 22
    v4_cidr_blocks      = var.trusted_ip_for_mgmt
  }

  ingress {
    protocol            = "TCP"
    description         = "HTTPS"
    port                = 443
    v4_cidr_blocks      = [var.private_subnet_a_cidr]
  }

  ingress {
    protocol            = "TCP"
    description         = "HTTP"
    port                = 80
    v4_cidr_blocks      = [var.private_subnet_a_cidr]
  }

  ingress {
    protocol            = "ICMP"
    description         = "ICMP"
    v4_cidr_blocks      = [var.private_subnet_a_cidr]
  }

  egress {
    protocol       = "ANY"
    description    = "outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

