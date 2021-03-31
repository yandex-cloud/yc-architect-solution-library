### VPC

resource "yandex_vpc_network" "network_a" {
  name = "network-a"
  folder_id = var.folder_id
}

resource "yandex_vpc_network" "network_b" {
  name = "network-b"
  folder_id = var.folder_id

}
resource "yandex_vpc_subnet" "subnet_a" {
  folder_id = var.folder_id

  count          = 2
  name           = "network-a-subnet-${count.index}"
  zone           = element(var.zones, count.index)
  network_id     = yandex_vpc_network.network_a.id
  v4_cidr_blocks = [element(var.network_a_cidrs, count.index)]
  route_table_id = element(yandex_vpc_route_table.network_a_rt.*.id, count.index)
}


resource "yandex_vpc_subnet" "subnet_b" {
  folder_id = var.folder_id

  name           = "network-b-subnet"
  zone           = element(var.zones, 1)
  network_id     = yandex_vpc_network.network_b.id
  v4_cidr_blocks = [var.network_b_cidr]
  route_table_id = yandex_vpc_route_table.network_b_rt.id

}

resource "yandex_vpc_address" "network_a_vpn_ip" {
  folder_id = var.folder_id

  count = 2
  name  = "network-a-vpn-ip-${count.index}"

  external_ipv4_address {
    zone_id = element(var.zones, count.index)
  }
}
resource "yandex_vpc_address" "network_b_vpn_ip" {
    folder_id = var.folder_id

  name = "network-site-a-vpn-ip"

  external_ipv4_address {
    zone_id = element(var.zones, 1)
  }
}

resource "yandex_vpc_route_table" "network_a_rt" {
  folder_id = var.folder_id

  count      = 2
  name       = "network-a-rt-${count.index}"
  network_id = yandex_vpc_network.network_a.id

  static_route {
    destination_prefix = var.network_b_cidr
    next_hop_address   = element(var.network_a_router_ips, count.index)
  }
}


### VPC




resource "yandex_vpc_route_table" "network_b_rt" {
  folder_id = var.folder_id

  network_id = yandex_vpc_network.network_b.id
  name       = "network-b-rt"

  static_route {
    destination_prefix = var.network_a_aggregated_prefix
    next_hop_address   = var.network_b_router_ip
  }
}



# if you don't have security groups please don't use this part or ask for security groups
resource "yandex_vpc_security_group" "network_a_sg" {
  folder_id = var.folder_id

  name       = "network_a_sg"
  network_id = yandex_vpc_network.network_a.id



  ingress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}


resource "yandex_vpc_security_group" "network_b_sg" {
  folder_id = var.folder_id

  name       = "network_b_sg"
  network_id = yandex_vpc_network.network_b.id



  ingress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}