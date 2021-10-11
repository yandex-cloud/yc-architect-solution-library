# ===============
# Input Variables
# ===============

variable "vm_name" {
  description = "VM Name"
  type = string
  default = "my-test-vm"

  validation {
    condition = can(regex("^[0-9a-z\\-]+$",var.vm_name))
    error_message = "VM name should use lower case chars only and not use a underscore."
  }
}

variable "vm_zone" {
  description = "VM Zone name"
  type = string
  default = "ru-central1-c"

  validation {
    condition = can(regex("^[0-9a-z\\-]+$",var.vm_zone))
    error_message = "VM name should use lower case chars only and not use a underscore."
  }
}

data "yandex_vpc_network" "vpc_net" {
  name = "default"
}

data "yandex_vpc_subnet" "vm_subnet" {
  subnet_id = data.yandex_vpc_network.vpc_net.subnet_ids[0]
}

data "yandex_compute_image" "vm_image" {
  family = "ubuntu-2004-lts"
}

locals {
  dns_ip = cidrhost(data.yandex_vpc_subnet.vm_subnet.v4_cidr_blocks[0],2)
  dns_config = templatefile("${path.module}/templates/Corefile", {dns_ip = local.dns_ip})
}
