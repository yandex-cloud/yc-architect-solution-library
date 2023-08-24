// Internal NLB for NAT instances
resource "yandex_lb_network_load_balancer" "s3_nlb" {
  folder_id   = var.folder_id
  name = "s3-nlb"
  type = "internal"

  listener {
    name = "https-listener"
    port = 443
    internal_address_spec {
      subnet_id  = yandex_vpc_subnet.nat_vm_subnets[0].id
      address = cidrhost(yandex_vpc_subnet.nat_vm_subnets[0].v4_cidr_blocks[0], 100)
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.s3_nat_group.id

    healthcheck {
      name = "https"
      timeout = 2
      interval = 3
      unhealthy_threshold = 3
      healthy_threshold = 3
      tcp_options {
        port = 443 
      }
    }
  }
}

// target group for s3_nlb
resource "yandex_lb_target_group" "s3_nat_group" {
  folder_id = var.folder_id
  name      = "s3-nat-group"

  dynamic "target" {
    for_each = yandex_compute_instance.nat_vm
    content {
      subnet_id = target.value.network_interface.0.subnet_id
      address   = target.value.network_interface.0.ip_address
    }
  }
}

