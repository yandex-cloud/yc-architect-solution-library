module "route_switcher" {
  source    = "./modules/route-switcher/"
  start_module          = false
  folder_id = yandex_resourcemanager_folder.folder4.id
  route_table_folder_list = [yandex_resourcemanager_folder.folder1.id, yandex_resourcemanager_folder.folder2.id, yandex_resourcemanager_folder.folder4.id, yandex_resourcemanager_folder.folder5.id]
  route_table_list      = [yandex_vpc_route_table.dmz-rt.id, yandex_vpc_route_table.app-rt.id, yandex_vpc_route_table.mgmt-rt.id, yandex_vpc_route_table.database-rt.id]
  router_healthcheck_port = 443
  back_to_primary = true
  routers = [
    {
      # fw-a
      healthchecked_ip = "${cidrhost(var.subnet-a_vpc_4, 10)}"
      healthchecked_subnet_id = yandex_vpc_subnet.subnet-a_vpc_4.id
      interfaces = [
        {
          # mgmt-int
          own_ip = yandex_compute_instance.fw-a.network_interface.0.ip_address
          backup_peer_ip = yandex_compute_instance.fw-b.network_interface.0.ip_address
        },
        {
          # dmz-int
          own_ip = yandex_compute_instance.fw-a.network_interface.2.ip_address
          backup_peer_ip = yandex_compute_instance.fw-b.network_interface.2.ip_address
        },
        {
          # app-int
          own_ip = yandex_compute_instance.fw-a.network_interface.3.ip_address
          backup_peer_ip = yandex_compute_instance.fw-b.network_interface.3.ip_address
        },
        {
          # database-int
          own_ip = yandex_compute_instance.fw-a.network_interface.4.ip_address
          backup_peer_ip = yandex_compute_instance.fw-b.network_interface.4.ip_address
        }
      ]
    },
    {
      # fw-b
      healthchecked_ip = "${cidrhost(var.subnet-b_vpc_4, 10)}"
      healthchecked_subnet_id = yandex_vpc_subnet.subnet-b_vpc_4.id
      interfaces = [
        {
          # mgmt-int
          own_ip = yandex_compute_instance.fw-b.network_interface.0.ip_address
          backup_peer_ip = yandex_compute_instance.fw-a.network_interface.0.ip_address
        },
        {
          # dmz-int
          own_ip = yandex_compute_instance.fw-b.network_interface.2.ip_address
          backup_peer_ip = yandex_compute_instance.fw-a.network_interface.2.ip_address
        },
        {
          # app-int
          own_ip = yandex_compute_instance.fw-b.network_interface.3.ip_address
          backup_peer_ip = yandex_compute_instance.fw-a.network_interface.3.ip_address
        },
        {
          # database-int
          own_ip = yandex_compute_instance.fw-b.network_interface.4.ip_address
          backup_peer_ip = yandex_compute_instance.fw-a.network_interface.4.ip_address
        }
      ]
    }
  ]
}
