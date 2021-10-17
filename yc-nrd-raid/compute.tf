# =================
# Compute Resources
# =================

resource "yandex_compute_disk" "disk1" {
  name = "nrd1"
  type = "network-ssd-nonreplicated"
  size = var.vm_disk_size 
  zone = var.vm_zone

  disk_placement_policy {
    disk_placement_group_id = yandex_compute_disk_placement_group.this.id
  }
}

resource "yandex_compute_disk" "disk2" {
  name = "nrd2"
  type = "network-ssd-nonreplicated"
  size = var.vm_disk_size
  zone = var.vm_zone

  disk_placement_policy {
    disk_placement_group_id = yandex_compute_disk_placement_group.this.id
  }
}

resource "yandex_compute_disk_placement_group" "this" {
  zone = var.vm_zone
}

resource "yandex_compute_instance" "vm_instance" {
  name = var.vm_name
  hostname = var.vm_name
  zone = var.vm_zone
  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.vm_image.id
    }
  }
  
  secondary_disk {
    disk_id = yandex_compute_disk.disk1.id
    device_name = yandex_compute_disk.disk1.name
  }

  secondary_disk {
    disk_id = yandex_compute_disk.disk2.id
    device_name = yandex_compute_disk.disk2.name
  }

  network_interface {
    subnet_id = data.yandex_vpc_subnet.vm_subnet.id
    nat = true
  }
  
  metadata = {
    user-data = templatefile("${path.module}/templates/vm-instance-tpl.yml",
      {
        ssh_key = "${file("~/.ssh/id_rsa.pub")}"
        disk_1 = format("virtio-%s",yandex_compute_disk.disk1.name)
        disk_2 = format("virtio-%s",yandex_compute_disk.disk2.name)
      }
    )
  }
}
