labels              = { tag = " demo" }
network_description = "terraform-created"
network_name        = "net-module"
domain_name         = "test.com"
domain_name_servers = ["8.8.8.8", "2.2.2.2"]
#vpc_id = "enp5v4es0f4vgdbou270"
#create_vpc = false
subnets = [

  {
    "v4_cidr_blocks" : "10.191.0.0/16",
    "zone" : "ru-central1-a"
  },
  {
    "v4_cidr_blocks" : "10.121.0.0/16",
    "zone" : "ru-central1-b"
  },
  {
    "v4_cidr_blocks" : "10.131.0.0/16",
    "zone" : "ru-central1-c"
  },
  {
    "v4_cidr_blocks" : "10.201.0.0/16",
    "zone" : "ru-central1-c"
  },
]
