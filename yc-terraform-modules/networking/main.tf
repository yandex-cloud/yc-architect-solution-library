### Datasource
data "yandex_client_config" "client" {}

### Locals
locals {
  folder_id = var.folder_id == null ? data.yandex_client_config.client.folder_id : var.folder_id
  vpc_id    = var.create_vpc ? yandex_vpc_network.this[0].id : var.vpc_id
}

### Network
resource "yandex_vpc_network" "this" {
  count       = var.create_vpc ? 1 : 0
  description = var.network_description
  name        = var.network_name
  labels      = var.labels
  folder_id   = local.folder_id
}

resource "yandex_vpc_subnet" "public" {
  for_each       =  var.public_subnets == null ? {} : { for v in var.public_subnets : v.v4_cidr_blocks => v }
  name           = "public-${var.network_name}-${each.value.zone}:${each.value.v4_cidr_blocks}"
  description    = "${var.network_name} subnet for zone ${each.value.zone}"
  v4_cidr_blocks = [each.value.v4_cidr_blocks]
  zone           = each.value.zone
  network_id     = local.vpc_id
  folder_id      = local.folder_id
  route_table_id = yandex_vpc_route_table.public.id
  dhcp_options {
    domain_name         = var.domain_name == null ? "internal." : var.domain_name
    domain_name_servers = var.domain_name_servers == null ? [cidrhost(each.value.v4_cidr_blocks, 2)] : var.domain_name_servers
    ntp_servers         = var.ntp_servers == null ? ["ntp0.NL.net", "clock.isc.org", "ntp.ix.ru"] : var.ntp_servers
  }

  labels = var.labels
}
resource "yandex_vpc_subnet" "private" {
  for_each       = var.private_subnets == null ? {} : { for v in var.private_subnets : v.v4_cidr_blocks => v }
  name           = "private-${var.network_name}-${each.value.zone}:${each.value.v4_cidr_blocks}"
  description    = "${var.network_name} subnet for zone ${each.value.zone}"
  v4_cidr_blocks = [each.value.v4_cidr_blocks]
  zone           = each.value.zone
  network_id     = local.vpc_id
  folder_id      = local.folder_id
  route_table_id = yandex_vpc_route_table.private.id
  dhcp_options {
    domain_name         = var.domain_name == null ? "internal." : var.domain_name
    domain_name_servers = var.domain_name_servers == null ? [cidrhost(each.value.v4_cidr_blocks, 2)] : var.domain_name_servers
    ntp_servers         = var.ntp_servers == null ? ["ntp0.NL.net", "clock.isc.org", "ntp.ix.ru"] : var.ntp_servers
  }

  labels = var.labels
}

## Routes
resource "yandex_vpc_gateway" "egress-gateway" {
  name  = "egress-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "public" {
  name = "${var.network_name}-public"
  network_id = local.vpc_id

  dynamic "static_route" {
    for_each = var.routes_public_subnets == null ? [] : var.routes_public_subnets
    content {
      destination_prefix = static_route.value["destination_prefix"]
      next_hop_address   = static_route.value["next_hop_address"]
    }
  }
  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = "${yandex_vpc_gateway.egress-gateway.id}"
  }
}
resource "yandex_vpc_route_table" "private" {
  name =  "${var.network_name}-private"
  network_id = local.vpc_id

  dynamic "static_route" {
    for_each = var.routes_private_subnets == null ? [] : var.routes_private_subnets
    content {
      destination_prefix = static_route.value["destination_prefix"]
      next_hop_address   = static_route.value["next_hop_address"]
    }
  }
}

## Default Security Group
resource "yandex_vpc_default_security_group" "default_sg" {
  count       = var.create_vpc ? 1 : 0
  description = "Default security group"
  network_id  = local.vpc_id
  labels      = var.labels

  ingress {
    protocol          = "ANY"
    description       = "Communication inside this SG"
    predefined_target = "self_security_group"

  }
  ingress {
    protocol       = "ANY"
    description    = "ssh"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22

  }
  ingress {
    protocol       = "ANY"
    description    = "RDP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 3389

  }
  ingress {
    protocol       = "ICMP"
    description    = "ICMP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }

  ingress {
    protocol       = "TCP"
    description    = "NLB health check"
    v4_cidr_blocks = ["198.18.235.0/24", "198.18.248.0/24"]
    from_port      = 0
    to_port        = 65535
  }

  egress {
    protocol       = "ANY"
    description    = "To internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
