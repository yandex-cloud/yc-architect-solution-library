output "subnets" {
  description = "Subnets used in vpc network by key:name"
  value = { for v in yandex_vpc_subnet.subnets : v.name => {
      "id" = v.id,
      "name" = v.name,
      "zone" = v.zone,
      "v4_cidr_blocks" = v.v4_cidr_blocks,
      "folder_id" = v.folder_id
    }
  }
}

output "network_id" {
  description = "network id"
  value = local.network_id
}
