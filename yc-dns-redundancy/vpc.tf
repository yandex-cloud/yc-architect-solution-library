# ===============
# VPC Resources
# ===============

# Create Network/VPC in all Zones
resource "yandex_vpc_network" "default" {
  name = var.net_name[0]
  description = var.net_name[1]
}

resource "yandex_vpc_subnet" this {
  count = length(var.subnet_list)
  name = var.subnet_list[count.index].name
  zone = var.subnet_list[count.index].zone
  v4_cidr_blocks = [var.subnet_list[count.index].prefix]
  network_id = yandex_vpc_network.default.id
  dhcp_options { 
    domain_name_servers = local.dns_set[count.index]
  }
}
