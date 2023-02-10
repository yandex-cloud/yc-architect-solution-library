# =================
# Compute resources
# =================

resource "yandex_compute_instance" "vm" {
  folder_id = var.folder_id
  name = var.vm_name
  hostname = var.vm_name
  platform_id = "standard-v3"
  zone = var.zone
  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.image.id
    }
  }
  
  network_interface {
    subnet_id = "${data.yandex_vpc_subnet.subnet.id}"
    nat = true
  }
  
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}