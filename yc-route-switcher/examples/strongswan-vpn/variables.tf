variable "public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "folder_id" {

}
variable "zones" {
  description = "Yandex Cloud default Zone for provisoned resources"
  default     = ["ru-central1-a", "ru-central1-b"]
}

variable "network_a_cidrs" {
  type = list(string)

  default = ["192.168.0.0/24", "192.168.1.0/24"]
}

variable "network_a_aggregated_prefix" {
  default = "192.168.0.0/16"
}

variable "network_a_router_ips" {
  default = ["192.168.0.10", "192.168.1.10"]
}

variable "network_b_cidr" {
  default = "172.16.0.0/24"
}


variable "network_b_router_ip" {
  default = "172.16.0.10"
}

variable "config_path" {
  default = "config.yaml"

}
