resource "yandex_compute_disk" "glusterdisk_a" {
  count = var.disk_count_per_vm * var.storage_node_per_zone
  zone  = yandex_vpc_subnet.net-a.zone

  allow_recreate = false
  size           = var.disk_size
  block_size     = var.disk_block_size
  type           = var.disk_type
}

resource "yandex_compute_disk" "glusterdisk_b" {
  count = (var.is_ha) ? var.disk_count_per_vm * var.storage_node_per_zone : 0
  zone  = yandex_vpc_subnet.net-b.zone

  allow_recreate = false
  size           = var.disk_size
  block_size     = var.disk_block_size
  type           = var.disk_type
}
resource "yandex_compute_disk" "glusterdisk_c" {
  count = (var.is_ha) ? var.disk_count_per_vm * var.storage_node_per_zone : 0
  zone  = yandex_vpc_subnet.net-c.zone

  allow_recreate = false
  size           = var.disk_size
  block_size     = var.disk_block_size
  type           = var.disk_type
}
