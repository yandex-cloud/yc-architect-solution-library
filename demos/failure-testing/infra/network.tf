module "network" {
  source              = "../modules/network"
  folder_id           = local.folder_id
  network_id          = var.network_id
  network_create      = var.network_id == null
  network_name        = var.network_name
  network_description = var.network_description
  subnets = [
    {
      "purpose" : "k8s",
      "zone" : "ru-central1-a",
      "v4_cidr_blocks" : "10.101.1.0/24",
      "route_table" : "inet-access"
    },
    {
      "purpose" : "k8s",
      "zone" : "ru-central1-b",
      "v4_cidr_blocks" : "10.101.2.0/24",
      "route_table" : "inet-access"
    },
    {
      "purpose" : "db",
      "zone" : "ru-central1-a",
      "v4_cidr_blocks" : "10.101.11.0/24",
      "route_table" : "inet-access"
    },
    {
      "purpose" : "db",
      "zone" : "ru-central1-b",
      "v4_cidr_blocks" : "10.101.12.0/24",
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
