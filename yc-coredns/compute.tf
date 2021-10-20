# =================
# Compute Resources
# =================

resource "yandex_compute_instance" "vm_instance" {
  name = var.vm_name
  hostname = var.vm_name
  zone = var.vm_zone
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
    subnet_id = data.yandex_vpc_subnet.vm_subnet.id
    nat = true
  }
  
  metadata = {
    user-data = templatefile("${path.module}/templates/vm-instance-tpl.yml",
      {
        ssh_key = "${file("~/.ssh/id_rsa.pub")}"
        coredns_config = local.dns_config
        coredns_systemd = "${file("${path.module}/templates/coredns-systemd")}"
        runcmd_script = "${file("${path.module}/templates/runcmd")}"
        dns_ip = "${local.dns_ip}"
      }
    )
  }
}
