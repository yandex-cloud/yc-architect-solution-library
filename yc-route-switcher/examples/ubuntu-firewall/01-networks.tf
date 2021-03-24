### VPC

resource "yandex_vpc_network" "network_a" {
  folder_id = var.folder_id
  name = "network-a"
}

resource "yandex_vpc_network" "network_b" {
  folder_id = var.folder_id

  name = "network-b"
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

  count          = 2
  name           = "network-b-subnet-${count.index}"
  zone           = element(var.zones, count.index)
  network_id     = yandex_vpc_network.network_b.id
  v4_cidr_blocks = [element(var.network_b_cidrs, count.index)]
  route_table_id = element(yandex_vpc_route_table.network_b_rt.*.id, count.index)
}


resource "yandex_vpc_route_table" "network_a_rt" {
  folder_id = var.folder_id

  count      = 2
  name       = "network-a-rt-${count.index}"
  network_id = yandex_vpc_network.network_a.id

  static_route {
    destination_prefix = var.network_b_aggregated_prefix
    next_hop_address   = element(var.network_a_firewall_addresses, count.index)
  }
}


resource "yandex_vpc_route_table" "network_b_rt" {
  folder_id = var.folder_id

  count      = 2
  name       = "network-b-rt-${count.index}"
  network_id = yandex_vpc_network.network_b.id

  static_route {
    destination_prefix = var.network_a_aggregated_prefix
    next_hop_address   = element(var.network_b_firewall_addresses, count.index)
  }
}


### VPC






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