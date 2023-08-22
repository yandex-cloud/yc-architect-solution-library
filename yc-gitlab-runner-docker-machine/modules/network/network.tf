data "yandex_vpc_network" "thenetwork" {
  network_id = var.network_id
  folder_id = var.folder_id
}

resource "yandex_vpc_network" "thenetwork" {
  count = var.network_create ? 1 : 0
  name = var.network_name
  description = var.network_description
  labels = var.labels
  folder_id = var.folder_id
}

resource "yandex_vpc_subnet" "subnets" {
  for_each = var.subnets == null ? {} : { for v in var.subnets : "${v.purpose}-${v.zone}" => v }
  name = "${each.value.purpose}-${each.value.zone}"
  description = "The ${each.value.purpose} subnet of the ${local.network_name} vpc in the zone ${each.value.zone}"
  v4_cidr_blocks = [each.value.v4_cidr_blocks]
  zone = each.value.zone
  network_id = local.network_id
  folder_id = each.value.folder_name == null ? var.folder_id : (var.folders[each.value.folder_name].id == null ? var.folder_id : var.folders[each.value.folder_name].id) 
  route_table_id = each.value.route_table == null ? null : yandex_vpc_route_table.route_tables[each.value.route_table].id
  dhcp_options {
    domain_name = var.domain_name == null ? "internal." : var.domain_name
    domain_name_servers = var.domain_name_servers == null ? [cidrhost(each.value.v4_cidr_blocks, 2)] : var.domain_name_servers
    ntp_servers = var.ntp_servers == null ? ["ntp0.NL.net", "clock.isc.org", "ntp.ix.ru"] : var.ntp_servers
  }
  labels = var.labels
}

resource "yandex_vpc_gateway" "egress_gateway" {
  count = var.gateway_id == null ? 1 : 0
  folder_id = var.folder_id
  name = "${local.network_name}-egress-gateway"
  description = "The egress gateway of ${local.network_name}"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "route_tables" {
  for_each = var.route_tables == null ? {} : { for v in var.route_tables : v.name => v }
  name = "${local.network_name}-${each.key}"
  network_id = local.network_id
  folder_id = var.folder_id
  dynamic "static_route" {
    for_each = var.route_tables == null ? [] : each.value.routes
    content {
      destination_prefix = static_route.value["destination_prefix"]
      next_hop_address = static_route.value["next_hop_address"] == "gateway" ? null : static_route.value["next_hop_address"]
      gateway_id = static_route.value["next_hop_address"] == "gateway" ? yandex_vpc_gateway.egress_gateway[0].id : null
    }
  }
}
