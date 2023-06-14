// create vpc
resource "yandex_vpc_network" "vpc" {
  name = var.vpc_name
  folder_id = var.folder_id
}

// create private subnets
resource "yandex_vpc_subnet" "private_subnet_a" {
  folder_id = var.folder_id
  name           = var.private_subnet_a_name
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.vpc.id
  v4_cidr_blocks = [var.private_subnet_a_cidr]
  route_table_id = yandex_vpc_route_table.nat_instance_rt.id
}

// create public subnets
resource "yandex_vpc_subnet" "public_subnet_a" {
  folder_id = var.folder_id
  name           = var.public_subnet_a_name
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.vpc.id
  v4_cidr_blocks = [var.public_subnet_a_cidr]
}

resource "yandex_vpc_subnet" "public_subnet_b" {
  folder_id = var.folder_id
  name           = var.public_subnet_b_name
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.vpc.id
  v4_cidr_blocks = [var.public_subnet_b_cidr]
}

// create static routes for NAT instances
resource "yandex_vpc_route_table" "nat_instance_rt" {
  folder_id = var.folder_id
  network_id = yandex_vpc_network.vpc.id
  name = "nat-instance-rt"

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = "${cidrhost(var.public_subnet_a_cidr, 10)}"
  }
}

// static public IP for nat-a
resource "yandex_vpc_address" "public_ip_nat_a" {
  name = "public-ip-nat-a"
  folder_id = var.folder_id
  external_ipv4_address {
    zone_id = "ru-central1-a"
  }
}

// static public IP for nat-b
resource "yandex_vpc_address" "public_ip_nat_b" {
  name = "public-ip-nat-b"
  folder_id = var.folder_id
  external_ipv4_address {
    zone_id = "ru-central1-b"
  }
}


