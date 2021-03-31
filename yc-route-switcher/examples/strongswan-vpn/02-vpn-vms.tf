
resource "yandex_compute_image" "vpn_instance" {
  source_family = "ipsec-instance-ubuntu"
    folder_id = "standard-images"

}

resource "random_string" "psk" {
  length  = 10
  upper   = false
  lower   = true
  number  = true
  special = false
}

data "yandex_vpc_address" "network_a_vpn_ip" {
  count      = 2
  address_id = yandex_vpc_address.network_a_vpn_ip[count.index].id
  folder_id = var.folder_id

}

data "yandex_vpc_address" "network_b_vpn_ip" {
  address_id = yandex_vpc_address.network_b_vpn_ip.id
  folder_id = var.folder_id

}



resource "yandex_compute_instance" "network_a_vpn_vm" {
  folder_id = var.folder_id

  count       = 2
  name        = "vpn-vm-network-a-${count.index}"
  hostname    = "vpn-vm-network-a-${count.index}"
  description = "vpn-vm-network-a-${count.index}"
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
      image_id = yandex_compute_image.vpn_instance.id
      type     = "network-ssd"
      size     = 33
    }
  }

  network_interface {
    subnet_id          = element(yandex_vpc_subnet.subnet_a.*.id, count.index)
    ip_address         = element(var.network_a_router_ips, count.index)
    nat                = true
    nat_ip_address     = element(data.yandex_vpc_address.network_a_vpn_ip.*.external_ipv4_address.0.address, count.index)
    security_group_ids = [yandex_vpc_security_group.network_a_sg.id]
  }

  metadata = {
    user-data = templatefile("${path.module}/templates/vpn.a.tpl.yaml",
      {

        ssh_key          = file(var.public_key_path)
        left_id          = element(data.yandex_vpc_address.network_a_vpn_ip.*.external_ipv4_address.0.address, count.index)
        leftsubnet       = element(var.network_a_cidrs, count.index)
        left_aggr_subnet = var.network_a_aggregated_prefix
        right            = data.yandex_vpc_address.network_b_vpn_ip.external_ipv4_address.0.address
        rightsubnet      = var.network_b_cidr
        psk              = random_string.psk.result
      }
    )
  }


}


resource "yandex_compute_instance" "network_b_vpn_vm" {
    folder_id = var.folder_id

  name        = "vpn-vm-network-b"
  hostname    = "vpn-vm-network-b"
  description = "vpn-vm-network-b"
  zone        = element(var.zones, 1)
  platform_id = "standard-v2"

  resources {
    cores         = 2
    memory        = 4
    core_fraction = "100"
  }
  allow_stopping_for_update = true
  boot_disk {
    initialize_params {
      image_id = yandex_compute_image.vpn_instance.id
      type     = "network-ssd"
      size     = 33
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet_b.id
    ip_address         = var.network_b_router_ip
    nat                = true
    nat_ip_address     = data.yandex_vpc_address.network_b_vpn_ip.external_ipv4_address.0.address
    security_group_ids = [yandex_vpc_security_group.network_b_sg.id]
  }

  metadata = {
    user-data = templatefile("${path.module}/templates/vpn.b.tpl.yaml",
      {

        ssh_key           = file(var.public_key_path)
        left_id           = data.yandex_vpc_address.network_b_vpn_ip.external_ipv4_address.0.address
        leftsubnet        = var.network_b_cidr
        right_a           = element(data.yandex_vpc_address.network_a_vpn_ip.*.external_ipv4_address.0.address, 0)
        right_b           = element(data.yandex_vpc_address.network_a_vpn_ip.*.external_ipv4_address.0.address, 1)
        rightsubnet_a     = element(var.network_a_cidrs, 0)
        rightsubnet_b     = element(var.network_a_cidrs, 1)
        right_aggr_subnet = var.network_a_aggregated_prefix
        psk               = random_string.psk.result
      }
    )
  }


}

