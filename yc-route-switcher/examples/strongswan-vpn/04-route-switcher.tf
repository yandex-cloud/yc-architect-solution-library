module "route_switcher_infra" {
  source                = "../../modules/multi-vpc-infra/"
  folder_id             = var.folder_id
  first_router_subnet   = element(yandex_vpc_subnet.subnet_a.*.id, 0)
  first_router_address  = element(var.network_a_router_ips, 0)
  second_router_subnet  = element(yandex_vpc_subnet.subnet_a.*.id, 1)
  second_router_address = element(var.network_a_router_ips, 1)
}


module "first_vpc_switcher" {
  source = "../../modules/multi-vpc-protected-network/"
  folder_id             = var.folder_id
  sa_id                 = module.route_switcher_infra.sa_id
  load_balancer_id      = module.route_switcher_infra.load_balancer_id
  target_group_id       = module.route_switcher_infra.target_group_id
  bucket_id             = module.route_switcher_infra.bucket_id
  access_key            = module.route_switcher_infra.access_key
  secret_key            = module.route_switcher_infra.secret_key
  first_router_address  = module.route_switcher_infra.first_router_address
  second_router_address = module.route_switcher_infra.second_router_address
  #values below will change in different networks
  vpc_id                = yandex_vpc_network.network_a.id
  first_az_rt           = element(yandex_vpc_route_table.network_a_rt.*.id, 0)
  first_az_subnet_list  = [yandex_vpc_subnet.subnet_a.0.id]
  second_az_rt          = element(yandex_vpc_route_table.network_a_rt.*.id, 1)
  second_az_subnet_list = [yandex_vpc_subnet.subnet_a.1.id]

}


