variable "public_key_path" {
  description = "Path to ssh public key"

  type    = string
  default = "~/.ssh/id_rsa.pub"
}

variable "folder_id" {
  description = "Yandex Cloud folder_id where everything should be deployed"

  type = string

}
variable "zones" {
  description = "Yandex Cloud default Zone for provisoned resources"
  type        = list(string)
  default     = ["ru-central1-a", "ru-central1-b"]
}

variable "network_a_cidrs" {
  description = "Cidrs for network a"
  type        = list(string)

  default = ["192.168.0.0/24", "192.168.1.0/24"]
}

variable "network_b_cidrs" {
  description = "Cidrs for network b"

  type    = list(string)
  default = ["172.16.0.0/24", "172.16.1.0/24"]
}


variable "network_a_aggregated_prefix" {
  description = "Network a aggregated prefix. Should aggregate cidrs from var.network_a_cidrs"
  type        = string
  default     = "192.168.0.0/16"
}

variable "network_b_aggregated_prefix" {
  description = "Network b aggregated prefix. Should aggregate cidrs from var.network_b_cidrs"

  type    = string
  default = "172.16.0.0/12"
}


variable "network_a_firewall_addresses" {
  description = "Network a router addresses , should be located in   var.network_a_cidrs"
  type        = list(string)
  default     = ["192.168.0.10", "192.168.1.10"]
}

variable "network_b_firewall_addresses" {
  description = "Network b router addresses , should be located in   var.network_b_cidrs"

  type    = list(string)
  default = ["172.16.0.10", "172.16.1.10"]
}

