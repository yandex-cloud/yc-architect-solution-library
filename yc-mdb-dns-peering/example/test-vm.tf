
data "yandex_compute_image" "base_image" {
  family = var.yc_image_family
}

resource "yandex_compute_instance" "dns_srv" {
  name        = "dns-test-srv1"
  platform_id = "standard-v2"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.base_image.id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.infra_subnet.0.id
    nat = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}
