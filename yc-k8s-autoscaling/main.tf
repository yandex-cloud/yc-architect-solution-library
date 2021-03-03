### VPC
resource "yandex_vpc_network" "this" {
  name        = var.network_name
  description = var.network_description

  labels = var.labels
}
resource "yandex_vpc_subnet" "this" {
  for_each       = { for v in var.subnets : v.zone => v }
  name           = "${var.network_name}-${each.value.zone}"
  description    = "${var.network_name} subnet for zone ${each.value.zone}"
  v4_cidr_blocks = each.value.v4_cidr_blocks
  zone           = each.value.zone
  network_id     = yandex_vpc_network.this.id
  labels         = var.labels

  depends_on = [
    yandex_vpc_network.this
  ]
}
### KMS
resource "yandex_kms_symmetric_key" "key" {
  name              = "k8s-symetric-key"
  description       = "description for key"
  default_algorithm = "AES_128"
  rotation_period   = "8760h" // equal to 1 year
}
### Datasource
data "yandex_client_config" "client" {}

### K8S
resource "yandex_iam_service_account" "k8s_sa" {
  name        = "k8smanager"
  description = "service account to manage k8s"
}

resource "yandex_resourcemanager_folder_iam_member" "service_account" {
  folder_id = data.yandex_client_config.client.folder_id
  member    = "serviceAccount:${yandex_iam_service_account.k8s_sa.id}"
  role      = "editor"
}

resource "yandex_kubernetes_cluster" "regional_cluster" {
  name        = "demo"
  description = "Demonstration of autoscaling"

  network_id = yandex_vpc_network.this.id
  master {
    regional {
      region = "ru-central1"

      dynamic "location" {
        for_each = yandex_vpc_subnet.this
        content {
          zone      = location.value.zone
          subnet_id = location.value.id
        }
      }
    }
    version   = "1.16"
    public_ip = true

    maintenance_policy {
      auto_upgrade = true

      maintenance_window {
        day        = "monday"
        start_time = "15:00"
        duration   = "3h"
      }

      maintenance_window {
        day        = "friday"
        start_time = "10:00"
        duration   = "4h30m"
      }
    }
  }
  service_ipv4_range      = var.k8s_service_ipv4_range
  cluster_ipv4_range      = var.k8s_pod_ipv4_range
  release_channel         = "REGULAR"
  network_policy_provider = "CALICO"
  service_account_id      = yandex_iam_service_account.k8s_sa.id
  node_service_account_id = yandex_iam_service_account.k8s_sa.id
  kms_provider {
    key_id = yandex_kms_symmetric_key.key.id
  }

  labels     = var.labels
  depends_on = [yandex_vpc_subnet.this, yandex_resourcemanager_folder_iam_member.service_account]
}

### K8s Node Groups

resource "yandex_kubernetes_node_group" "nodes" {
  for_each   = yandex_vpc_subnet.this
  cluster_id = yandex_kubernetes_cluster.regional_cluster.id
  name       = "ng-${each.value.zone}"
  version    = "1.16"

  instance_template {
    platform_id = "standard-v2"
    nat         = true

    resources {
      memory = 4
      cores  = 2
    }

    boot_disk {
      type = "network-ssd"
      size = 64
    }

    scheduling_policy {
      preemptible = false
    }
  }

  scale_policy {
    auto_scale {
      min     = 1
      max     = 3
      initial = 1
    }
  }

  allocation_policy {
    location {
      zone      = each.value.zone
      subnet_id = each.value.id
    }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true
  }
}
