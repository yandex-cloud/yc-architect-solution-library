resource "yandex_iam_service_account" "route_switcher_sa" {
  folder_id = var.folder_id
  name = "route-switcher-sa-${random_string.prefix.result}"
}

resource "yandex_lb_target_group" "route_switcher_tg" {
  folder_id = var.folder_id
  name      = "route-switcher-tg-${random_string.prefix.result}"
  region_id = "ru-central1"

  dynamic "target" {
    for_each = var.routers == null ? [] : var.routers
    content {
      address = target.value["healthchecked_ip"]
      subnet_id   = target.value["healthchecked_subnet_id"]
    }
  }
}

resource "yandex_lb_network_load_balancer" "route_switcher_lb" {
  folder_id = var.folder_id
  name = "route-switcher-lb-${random_string.prefix.result}"
  type = "internal"

  listener {
    name = "route-switcher-listener"
    port = 9999
    internal_address_spec {
      subnet_id = var.routers[0]["healthchecked_subnet_id"]
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.route_switcher_tg.id

    healthcheck {
      name = "tcp"
      timeout = 2
      interval = 3
      unhealthy_threshold = 3
      healthy_threshold = 3
      tcp_options {
        port = var.router_healthcheck_port
      }
    }
  }
}

resource "random_string" "prefix" {
  length  = 10
  upper   = false
  lower   = true
  numeric  = true
  special = false
}

resource "yandex_iam_service_account_static_access_key" "route_switcher_sa_s3_keys" {
  service_account_id = yandex_iam_service_account.route_switcher_sa.id
}

resource "yandex_resourcemanager_folder_iam_member" "route_switcher_sa_roles" {
  count     = length(var.route_switcher_sa_roles)
  folder_id = var.folder_id
  role   = var.route_switcher_sa_roles[count.index]
  member = "serviceAccount:${yandex_iam_service_account.route_switcher_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "route_switcher_vpc_sa_roles" {
  count     = length(var.route_table_folder_list)
  folder_id = var.route_table_folder_list[count.index]
  role   = "vpc.privateAdmin"
  member = "serviceAccount:${yandex_iam_service_account.route_switcher_sa.id}"
}

resource "yandex_storage_bucket" "route_switcher_bucket" {
  depends_on = [yandex_resourcemanager_folder_iam_member.route_switcher_sa_roles]
  bucket     = "route-switcher-${random_string.prefix.result}"
  access_key = yandex_iam_service_account_static_access_key.route_switcher_sa_s3_keys.access_key
  secret_key = yandex_iam_service_account_static_access_key.route_switcher_sa_s3_keys.secret_key
}

resource "yandex_storage_object" "route_switcher_config" {
  bucket     = yandex_storage_bucket.route_switcher_bucket.id
  access_key = yandex_iam_service_account_static_access_key.route_switcher_sa_s3_keys.access_key
  secret_key = yandex_iam_service_account_static_access_key.route_switcher_sa_s3_keys.secret_key
  key        = "route-switcher-config.yaml"
  content    = templatefile("${path.module}/templates/route.switcher.tpl.yaml",
    {
      load_balancer_id      = yandex_lb_network_load_balancer.route_switcher_lb.id
      target_group_id       = yandex_lb_target_group.route_switcher_tg.id
      route_tables          = var.route_table_list
      routers = var.routers
    }
  )
}