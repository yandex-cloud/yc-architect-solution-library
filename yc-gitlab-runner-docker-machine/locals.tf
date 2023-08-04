locals {
  folder_id  = var.folder_id == null ? data.yandex_client_config.client.folder_id : var.folder_id
  cloud_id   = var.cloud_id == null ? data.yandex_client_config.client.cloud_id : var.cloud_id
  subnet_id  = var.subnet_id == null ? module.network[0].subnets["${var.purpose}-${var.default_zone}"].id : var.subnet_id
  network_id = var.network_create == true ? module.network[0].network_id : var.network_id

  template_vars = {
    cloud_id               = local.cloud_id
    folder_id              = local.folder_id
    subnet_id              = local.subnet_id
    security_groups        = var.security_group_create ? yandex_vpc_security_group.security_group_worker[0].id : ""
    zone                   = var.default_zone
    worker_runners_limit   = var.worker_runners_limit
    worker_use_internal_ip = var.worker_use_internal_ip
    worker_image_family    = var.worker_image_family
    worker_image_id        = var.worker_image_id
    worker_cores           = var.worker_cores
    worker_disk_type       = var.worker_disk_type
    worker_disk_size       = var.worker_disk_size
    worker_memory          = var.worker_memory
    worker_preemptible     = var.worker_preemptible
    worker_platform_id     = var.worker_platform_id
    secret_id              = yandex_lockbox_secret.gitlab_token.id
  }
}
