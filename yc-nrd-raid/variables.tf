# ===============
# Input Variables
# ===============

variable "vm_name" {
  description = "VM Name"
  type = string
  default = "nrd-raid-test"

  validation {
    condition = can(regex("^[0-9a-z\\-]+$",var.vm_name))
    error_message = "VM name should use lower case chars only and not use a underscore."
  }
}

variable "vm_zone" {
  description = "VM Zone name"
  type = string
  default = "ru-central1-a"

  validation {
    condition = can(regex("^[0-9a-z\\-]+$",var.vm_zone))
    error_message = "VM name should use lower case chars only and not use a underscore."
  }
}

variable "vm_disk_size" {
  description = "VM disk size for single disk in array. All disks will be created the same size."
  type = number
  default = 93 # A non-replicated disk's size must be a multiple of 93 GB.
}


data "yandex_vpc_network" "vpc_net" {
  name = "default"
}

data "yandex_vpc_subnet" "vm_subnet" {
  name = local.vm_subnet_name
}

data "yandex_compute_image" "vm_image" {
  family = "ubuntu-2004-lts"
}

locals {
  vm_subnet_name = format("%s-%s",data.yandex_vpc_network.vpc_net.name, var.vm_zone)
}