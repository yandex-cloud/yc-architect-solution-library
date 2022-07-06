# =============================================
# Kubernetes cluster & Node Group Configuration
# =============================================

resource "yandex_kubernetes_cluster" "k8s" {
  name                    = "k8s"
  release_channel         = "RAPID"
  network_id              = var.net_id
  service_account_id      = var.sa_id
  node_service_account_id = var.sa_id

  master {
    zonal {
      zone = var.zone_id
      subnet_id = var.subnet_id
    }
    public_ip = false
    version   = "1.21"
  }
}

resource "yandex_kubernetes_node_group" "group_1" {
  cluster_id = yandex_kubernetes_cluster.k8s.id
  name       = "group-1"
  version    = "1.21"

  scale_policy {
    fixed_scale {
      size = 1
    }
  }

  allocation_policy {
    location {
      zone = var.zone_id
    }
  }

  instance_template {
    platform_id = "standard-v2"
    resources {
      cores         = 2
      core_fraction = 20
      memory        = 8
    }

    boot_disk {
      type = "network-hdd"
      size = 40
    }

    network_interface {
      nat        = false
      subnet_ids = [var.subnet_id]
    }

    metadata = {
      ssh-keys = "admin:${file("~/.ssh/id_rsa.pub")}"
    }
  }
}
