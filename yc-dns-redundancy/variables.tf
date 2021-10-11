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

variable "net_name" {
  description = "Network/VPC Name. Created at all Zones"
  type = list(string)
  default = ["my-network", "My network description."]

  validation {
    condition = can(regex("^[0-9a-z\\-]+$",var.net_name[0]))
    error_message = "Network name should use lower case chars only and not use a underscore."
  }
}

variable "subnet_list" {
  description = "Subnet structure primitive"
  type = list(object({
    name = string,
    zone = string,
    prefix = string
  }))

  default = [
    { name = "sub1", zone = "ru-central1-a", prefix = "10.1.1.128/25" },
    { name = "sub2", zone = "ru-central1-b", prefix = "10.2.2.0/24" },
    { name = "sub3", zone = "ru-central1-c", prefix = "10.3.3.64/28" },
  ]

  validation {
    condition = length(var.subnet_list) >= 1
    error_message = "At least one Subnet/Zone should be used."
  }
}

data "yandex_compute_image" "vm_image" {
  family = "ubuntu-2004-lts"
}

locals {
  # make a list with 2nd IPv4 address on each subnet
  dns_base = [ for el in var.subnet_list : cidrhost(el.prefix,2) ]
  # build a dns server list (dns_set) for each subnet where:
  # 1st element in the list -> local active DNS server
  # 2nd and subsequent elements in the list -> dns_base exclude the active local DNS server IP
  dns_set = [ for el in local.dns_base : concat( [el], tolist(setsubtract(local.dns_base, [el]))) ]
}
