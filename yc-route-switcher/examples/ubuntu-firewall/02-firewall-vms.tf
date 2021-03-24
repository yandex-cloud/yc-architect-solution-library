
resource "yandex_compute_image" "firewall_instance" {
  source_family = "ipsec-instance-ubuntu"
}

resource "random_string" "project_id" {
  
  length  = 10
  upper   = false
  lower   = true
  number  = true
  special = false
}


resource "yandex_compute_instance" "firewall" {
  folder_id = var.folder_id

  count       = 2
  name        = "firewall-vm-${count.index}"
  hostname    = "firewall-vm--${count.index}"
  description = "firewall-vm--${count.index}"
  zone        = element(var.zones, count.index)
  platform_id = "standard-v2"

  resources {
    cores         = 2
    memory        = 4
    core_fraction = "100"
  }
  allow_stopping_for_update = true
  boot_disk {
    initialize_params {
      image_id = yandex_compute_image.firewall_instance.id
      type     = "network-ssd"
      size     = 33
    }
  }

  network_interface {
    subnet_id          = element(yandex_vpc_subnet.subnet_a.*.id, count.index)
    ip_address         = element(var.network_a_firewall_addresses, count.index)
    security_group_ids = [yandex_vpc_security_group.network_a_sg.id]
  }

  network_interface {
    subnet_id          = element(yandex_vpc_subnet.subnet_b.*.id, count.index)
    ip_address         = element(var.network_b_firewall_addresses, count.index)
    security_group_ids = [yandex_vpc_security_group.network_b_sg.id]
  }

  metadata = {
    user-data = templatefile("${path.module}/templates/firewall.tpl.yaml",
      {

        ssh_key                     = file(var.public_key_path)
        network_a_aggregated_prefix = var.network_a_aggregated_prefix
        network_a_vpc_gateway       = cidrhost(element(var.network_a_cidrs, count.index), 1)
        network_b_aggregated_prefix = var.network_b_aggregated_prefix
        network_b_vpc_gateway       = cidrhost(element(var.network_b_cidrs, count.index), 1)
      }
    )
  }


}
