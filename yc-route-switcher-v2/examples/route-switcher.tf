module "route_switcher" {
  source    = "../route-switcher/"
  start_module          = false
  folder_id = var.folder_id
  route_table_folder_list = [var.folder_id]
  route_table_list      = [yandex_vpc_route_table.nat_instance_rt.id]
  router_healthcheck_port = 22
  back_to_primary = true
  routers = [
    {
      # nat-a
      healthchecked_ip = yandex_compute_instance.nat_a.network_interface.0.ip_address
      healthchecked_subnet_id = yandex_vpc_subnet.public_subnet_a.id
      interfaces = [
        {
          # private-int
          own_ip = yandex_compute_instance.nat_a.network_interface.0.ip_address
          backup_peer_ip = yandex_compute_instance.nat_b.network_interface.0.ip_address
        }
      ]
    },
    {
      # nat-b
      healthchecked_ip = yandex_compute_instance.nat_b.network_interface.0.ip_address
      healthchecked_subnet_id = yandex_vpc_subnet.public_subnet_b.id
      interfaces = [
        {
          # private-int
          own_ip = yandex_compute_instance.nat_b.network_interface.0.ip_address
          backup_peer_ip = yandex_compute_instance.nat_a.network_interface.0.ip_address
        }
      ]
    }
  ]
}
