resource "yandex_compute_instance" "client_node_a" {
  count                     = var.client_node_per_zone
  allow_recreate            = true
  allow_stopping_for_update = true
  zone                      = yandex_vpc_subnet.net-a.zone
  platform_id               = "standard-v3"
  name                      = format("client%02d", count.index + 1)
  hostname                  = format("client%02d", count.index + 1)

  resources {
    cores         = var.client_cpu_count
    memory        = var.client_memory_count
    core_fraction = 100
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.net-a.id
    nat       = count.index == 0 ? true : false
  }

  boot_disk {
    mode = "READ_WRITE"
    initialize_params {
      image_id = data.yandex_compute_image.centos8.image_id
      size     = 20
    }
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    user-data = templatefile("${path.module}/metadata/cloud-init.yaml", {
      local_pubkey   = file(var.local_pubkey_path)
      master_pubkey  = trimspace(tls_private_key.master_key.public_key_openssh)
      master_privkey = split("\n", tls_private_key.master_key.private_key_openssh)
    })
  }
}

resource "yandex_compute_instance" "client_node_b" {
  count                     = (var.is_ha) ? var.client_node_per_zone : 0
  allow_recreate            = true
  allow_stopping_for_update = true
  zone                      = yandex_vpc_subnet.net-b.zone
  platform_id               = "standard-v3"
  name                      = format("client%02d", var.client_node_per_zone + count.index + 1)
  hostname                  = format("client%02d", var.client_node_per_zone + count.index + 1)

  resources {
    cores         = var.client_cpu_count
    memory        = var.client_memory_count
    core_fraction = 100
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.net-b.id
    nat       = false
  }

  boot_disk {
    mode = "READ_WRITE"
    initialize_params {
      image_id = data.yandex_compute_image.centos8.image_id
      size     = 20
    }
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    user-data = templatefile("${path.module}/metadata/cloud-init.yaml", {
      local_pubkey   = file(var.local_pubkey_path)
      master_pubkey  = trimspace(tls_private_key.master_key.public_key_openssh)
      master_privkey = split("\n", tls_private_key.master_key.private_key_openssh)
    })
  }
}

resource "yandex_compute_instance" "client_node_c" {
  count                     = (var.is_ha) ? var.client_node_per_zone : 0
  allow_recreate            = true
  allow_stopping_for_update = true
  zone                      = yandex_vpc_subnet.net-c.zone
  platform_id               = "standard-v3"
  name                      = format("client%02d", var.client_node_per_zone * 2 + count.index + 1)
  hostname                  = format("client%02d", var.client_node_per_zone * 2 + count.index + 1)

  resources {
    cores         = var.client_cpu_count
    memory        = var.client_memory_count
    core_fraction = 100
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.net-c.id
    nat       = false
  }

  boot_disk {
    mode = "READ_WRITE"
    initialize_params {
      image_id = data.yandex_compute_image.centos8.image_id
      size     = 20
    }
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    user-data = templatefile("${path.module}/metadata/cloud-init.yaml", {
      local_pubkey   = file(var.local_pubkey_path)
      master_pubkey  = trimspace(tls_private_key.master_key.public_key_openssh)
      master_privkey = split("\n", tls_private_key.master_key.private_key_openssh)
    })
  }
}
