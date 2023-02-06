data "yandex_compute_image" "centos8" {
  family = "centos-stream-8"
}

resource "yandex_compute_instance" "storage_node_a" {
  count                     = var.storage_node_per_zone
  allow_recreate            = true
  allow_stopping_for_update = true
  zone                      = yandex_vpc_subnet.net-a.zone
  platform_id               = "standard-v3"
  name                      = format("gluster%02d", count.index + 1)
  hostname                  = format("gluster%02d", count.index + 1)

  resources {
    cores         = var.storage_cpu_count
    memory        = var.storage_memory_count
    core_fraction = 100
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.net-a.id
  }

  boot_disk {
    mode = "READ_WRITE"
    initialize_params {
      image_id = data.yandex_compute_image.centos8.image_id
    }
  }

  dynamic "secondary_disk" {
    for_each = range(var.disk_count_per_vm)
    content {
      auto_delete = true
      disk_id     = yandex_compute_disk.glusterdisk_a[count.index * var.disk_count_per_vm + secondary_disk.key].id
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

resource "yandex_compute_instance" "storage_node_b" {
  count                     = (var.is_ha) ? var.storage_node_per_zone : 0
  allow_recreate            = true
  allow_stopping_for_update = true
  zone                      = yandex_vpc_subnet.net-b.zone
  platform_id               = "standard-v3"
  name                      = format("gluster%02d", count.index + 1 + var.storage_node_per_zone)
  hostname                  = format("gluster%02d", count.index + 1 + var.storage_node_per_zone)

  resources {
    cores         = var.storage_cpu_count
    memory        = var.storage_memory_count
    core_fraction = 100
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.net-b.id
  }

  boot_disk {
    mode = "READ_WRITE"
    initialize_params {
      image_id = data.yandex_compute_image.centos8.image_id
    }
  }

  dynamic "secondary_disk" {
    for_each = range(var.disk_count_per_vm)
    content {
      auto_delete = true
      disk_id     = yandex_compute_disk.glusterdisk_b[count.index * var.disk_count_per_vm + secondary_disk.key].id
    }
  }

  metadata = {
    user-data = templatefile("${path.module}/metadata/cloud-init.yaml", {
      local_pubkey   = file(var.local_pubkey_path)
      master_pubkey  = trimspace(tls_private_key.master_key.public_key_openssh)
      master_privkey = split("\n", tls_private_key.master_key.private_key_openssh)
    })
  }
}

resource "yandex_compute_instance" "storage_node_c" {
  count                     = (var.is_ha) ? var.storage_node_per_zone : 0
  allow_recreate            = true
  allow_stopping_for_update = true
  zone                      = yandex_vpc_subnet.net-c.zone
  platform_id               = "standard-v3"
  name                      = format("gluster%02d", count.index + 1 + var.storage_node_per_zone * 2)
  hostname                  = format("gluster%02d", count.index + 1 + var.storage_node_per_zone * 2)

  resources {
    cores         = var.storage_cpu_count
    memory        = var.storage_memory_count
    core_fraction = 100
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.net-c.id
  }

  boot_disk {
    mode = "READ_WRITE"
    initialize_params {
      image_id = data.yandex_compute_image.centos8.image_id
    }
  }

  dynamic "secondary_disk" {
    for_each = range(var.disk_count_per_vm)
    content {
      auto_delete = true
      disk_id     = yandex_compute_disk.glusterdisk_c[count.index * var.disk_count_per_vm + secondary_disk.key].id
    }
  }

  metadata = {
    user-data = templatefile("${path.module}/metadata/cloud-init.yaml", {
      local_pubkey   = file(var.local_pubkey_path)
      master_pubkey  = trimspace(tls_private_key.master_key.public_key_openssh)
      master_privkey = split("\n", tls_private_key.master_key.private_key_openssh)
    })
  }
}
