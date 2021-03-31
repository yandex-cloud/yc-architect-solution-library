data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-1804-lts"
  folder_id = "standard-images"

}


resource "yandex_compute_instance" "network_a_user_vm" {
  folder_id = var.folder_id

  count       = 2
  name        = "network-a-user-vm-${count.index}"
  hostname    = "network-a-user-vm-${count.index}"
  platform_id = "standard-v2"
  zone        = element(var.zones, count.index)

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
    }
  }

  network_interface {
    subnet_id          = element(yandex_vpc_subnet.subnet_a.*.id, count.index)
    nat                = true
    security_group_ids = [yandex_vpc_security_group.network_a_sg.id]
  }

  metadata = {
    foo      = "bar"
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}


resource "yandex_compute_instance" "network_b_user_vm" {
  folder_id = var.folder_id

  name        = "network-b-user-vm"
  hostname = "network-b-user-vm"
  platform_id = "standard-v2"
  zone        = element(var.zones, 1)

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet_b.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.network_b_sg.id]
  }

  metadata = {
    foo      = "bar"
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}