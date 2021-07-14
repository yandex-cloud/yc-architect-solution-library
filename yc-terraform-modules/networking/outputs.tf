output "vpc_id" {
  description = "ID of created network for internal communications"
  value       = var.create_vpc ? yandex_vpc_network.this[0].id : null
}

output "zones" {
  description = "List of zones used in vpc network"
  value       = distinct([for subnet in yandex_vpc_subnet.this : subnet.zone])
}

output "v4_cidr_blocks" {
  description = "List of v4_cidr_blocks used in vpc network"
  value       = flatten([for subnet in yandex_vpc_subnet.this : subnet.v4_cidr_blocks])
}

output "subnets" {
  description = "List of maps of subnets used in vpc network: key = v4_cidr_block"
  value = { for v in yandex_vpc_subnet.this : v.v4_cidr_blocks[0] => {
    "id"   = v.id,
    "name" = v.name,
    "zone" = v.zone
    }
  }
}
