// Internal NLB for NAT instances
resource "yandex_lb_network_load_balancer" "s3_nlb" {
  folder_id   = var.folder_id
  name = "s3-nlb"
  type = "internal"

  listener {
    name = "https-listener"
    port = 443
    internal_address_spec {
      subnet_id  = length(var.subnet_id_list) == 0 ? yandex_vpc_subnet.nat_instances_subnets[0].id : var.subnet_id_list[0]
      address = length(var.subnet_id_list) == 0 ? "${cidrhost(yandex_vpc_subnet.nat_instances_subnets[0].v4_cidr_blocks[0], 100)}" : "${cidrhost(data.yandex_vpc_subnet.first_subnet[0].v4_cidr_blocks[0], 100)}"
    }
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.nat_instances_ig.load_balancer.0.target_group_id

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
