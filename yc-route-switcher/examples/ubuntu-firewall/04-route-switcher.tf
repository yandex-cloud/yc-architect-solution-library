module "route_switcher_infra" {
  source    = "../../modules/multi-vpc-infra/"
  folder_id = var.folder_id
  # usually a management subnet. used for healthkeaking status of the appliance
  first_router_subnet   = element(yandex_vpc_subnet.subnet_a.*.id, 0)
  first_router_address  = element(var.network_a_firewall_addresses, 0)
  second_router_subnet  = element(yandex_vpc_subnet.subnet_a.*.id, 1)
  second_router_address = element(var.network_a_firewall_addresses, 1)
}


module "network_a_protected" {
  source = "../../modules/multi-vpc-protected-network/"
  #values below should be used the same in different protected networks
  sa_id                 = module.route_switcher_infra.sa_id
  load_balancer_id      = module.route_switcher_infra.load_balancer_id
  target_group_id       = module.route_switcher_infra.target_group_id
  bucket_id             = module.route_switcher_infra.bucket_id
  access_key            = module.route_switcher_infra.access_key
  secret_key            = module.route_switcher_infra.secret_key
  first_router_address  = module.route_switcher_infra.first_router_address
  second_router_address = module.route_switcher_infra.second_router_address
  #values below will change in different folders if network are located in different folders
  folder_id = var.folder_id
  #values below will change in different networks
  vpc_id = yandex_vpc_network.network_a.id
  # first_az_rt is usually an active rt in first az , but back become backup if second_az appliace fails
  first_az_rt          = element(yandex_vpc_route_table.network_a_rt.*.id, 0)
  first_az_subnet_list = yandex_vpc_subnet.subnet_a.*.id
  # second_az_rt is usually an active rt in second az , but back become backup if first_az appliace fails
  second_az_rt          = element(yandex_vpc_route_table.network_a_rt.*.id, 1)
  second_az_subnet_list = []

}


module "network_b_protected" {
  #values below will change in different networks
  source = "../../modules//multi-vpc-protected-network/"
  #values below should be used the same in different protected networks
  sa_id                 = module.route_switcher_infra.sa_id
  load_balancer_id      = module.route_switcher_infra.load_balancer_id
  target_group_id       = module.route_switcher_infra.target_group_id
  bucket_id             = module.route_switcher_infra.bucket_id
  access_key            = module.route_switcher_infra.access_key
  secret_key            = module.route_switcher_infra.secret_key
  first_router_address  = module.route_switcher_infra.first_router_address
  second_router_address = module.route_switcher_infra.second_router_address
  #values below will change in different folders if network are located in different folders
  folder_id = var.folder_id
  #values below will change in different networks
  vpc_id = yandex_vpc_network.network_b.id
  # first_az_rt is usually an active rt in first az , but back become backup if second_az appliace fails
  first_az_rt          = element(yandex_vpc_route_table.network_b_rt.*.id, 0)
  first_az_subnet_list = yandex_vpc_subnet.subnet_b.*.id
  # second_az_rt is usually an active rt in second az , but back become backup if first_az appliace fails
  second_az_rt          = element(yandex_vpc_route_table.network_b_rt.*.id, 1)
  second_az_subnet_list = []

}





