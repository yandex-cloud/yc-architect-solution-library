// Create Load Balancers-------------------

// ALB for FW cluster
resource "yandex_alb_load_balancer" "fw-alb" {
  name = "fw-alb"
  network_id = yandex_vpc_network.vpc_name_3.id
  folder_id = yandex_resourcemanager_folder.folder3.id

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.subnet-a_vpc_3.id
    }
    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.subnet-b_vpc_3.id
    }
  }

  listener {
    name = "public-service"
    endpoint {
      address {
        external_ipv4_address {
          address = yandex_vpc_address.public-ip-fw-alb.external_ipv4_address.0.address
        }
      }
      ports = [var.public_app_port]
    }
    stream {
      handler {
        backend_group_id = yandex_alb_backend_group.fw-alb-bg.id
      }
    }
  }

  security_group_ids = [yandex_vpc_security_group.public-fw-alb-sg.id]
}

// Backend group for ALB FW
resource "yandex_alb_backend_group" "fw-alb-bg" {
  name = "fw-alb-bg"
  folder_id = yandex_resourcemanager_folder.folder3.id
  session_affinity { # required for session affinity https://cloud.yandex.com/en-ru/docs/application-load-balancer/concepts/backend-group#session-affinity
    connection {
      source_ip = true
    }
  }

  stream_backend {
    name             = "fw-alb-backend"
    port             = var.internal_app_port
    target_group_ids = [yandex_alb_target_group.fw-alb-tg.id]
    load_balancing_config {
      mode = "MAGLEV_HASH" # required for session affinity
    }
    healthcheck {
      timeout  = "1s"
      interval = "3s"
      healthy_threshold = "3"
      unhealthy_threshold = "3"
      healthcheck_port = var.internal_app_port
      stream_healthcheck {
      }
    }
  }
}

// Target group for ALB FW
resource "yandex_alb_target_group" "fw-alb-tg" {
  name      = "fw-alb-tg"
  folder_id = yandex_resourcemanager_folder.folder3.id

  target {
    subnet_id   = yandex_vpc_subnet.subnet-a_vpc_3.id
    ip_address  = yandex_compute_instance.fw-a.network_interface.1.ip_address
  }

  target {
    subnet_id   = yandex_vpc_subnet.subnet-b_vpc_3.id
    ip_address  = yandex_compute_instance.fw-b.network_interface.1.ip_address
  }
}

// NLB for web-servers instance group in dmz segment
resource "yandex_lb_network_load_balancer" "dmz-web-server-nlb" {
  folder_id   = yandex_resourcemanager_folder.folder1.id
  name = "dmz-web-server-nlb"
  type = "internal"

  listener {
    name = "public-service"
    port = var.internal_app_port
    internal_address_spec {
      subnet_id  = yandex_vpc_subnet.subnet-a_vpc_1.id
      address = "${cidrhost(var.subnet-a_vpc_1, 100)}"
    }
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.dmz-web-server-ig.load_balancer.0.target_group_id

    healthcheck {
      name = "internal-app-port"
      tcp_options {
        port = var.internal_app_port 
      }
    }
  }
}