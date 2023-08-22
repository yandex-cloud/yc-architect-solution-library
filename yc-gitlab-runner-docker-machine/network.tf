module "network" {
  count               = var.subnet_id == null ? 1 : 0
  source              = "./modules/network"
  cloud_id            = local.cloud_id
  folder_id           = local.folder_id
  network_id          = var.network_id
  network_create      = var.network_id == null
  network_name        = var.network_name
  network_description = var.network_description
  subnets = [
    {
      "purpose" : var.purpose,
      "zone" : var.default_zone,
      "v4_cidr_blocks" : var.network_cidr,
      "route_table" : "inet-access"
    }
  ]
  route_tables = [
    {
      "name" : "inet-access",
      "routes" : [
        {
          "destination_prefix" : "0.0.0.0/0",
          "next_hop_address" : "gateway"
        }
      ]
    }
  ]
}
