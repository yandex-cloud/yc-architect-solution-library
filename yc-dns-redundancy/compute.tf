# =================
# Compute Resources
# =================

resource "yandex_compute_instance" "vm_instance" {
  name = var.vm_name
  hostname = var.vm_name
  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.vm_image.id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.this[0].id
    nat       = true
  }

  metadata = {
    user-data = templatefile("${path.module}/templates/vm-instance-tpl.yml",
      {
        ssh_key = "${file("~/.ssh/id_rsa.pub")}"
      }
    )
  }
}
