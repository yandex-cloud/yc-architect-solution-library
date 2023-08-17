variable "folder_id" {
  type = string
  description = "Folder id for resources"
  default = null
}

variable "vpc_id" {
  type = string
  description = "VPC id for resources. Default create new network."
  default = null
}

variable "subnet_id_list" {
  type        = list(string)
  description = "List of subnet id for NAT instances. Default create new subnets, one in every availability zone."
  default     = []
}

variable "nat_instances_count" {
  type = number
  description = "Number of NAT instances for Instance group"
  default = 2
}

variable "trusted_ip_for_mgmt" {
  type = list(string)
  description = "List of trusted public IP addresses for connection to NAT-instances"
  default = []
}

variable "trusted_cloud_nets" {
  type = list(string)
  description = "List of trusted cloud internal networks for connection to Object Storage through NAT-instances"
  default = []
}

variable "vm_username" {
   type = string
   description = "Username for VMs"
   default = "admin"
}

variable "s3_ip" {
  type        = string
  description = "Yandex Object Storage Endpoint IP address"
  default     = "213.180.193.243"
}

variable "s3_fqdn" {
  type        = string
  description = "Yandex Object Storage Endpoint FQDN"
  default     = "storage.yandexcloud.net"
}

variable "yc_availability_zones" {
  type = list(string)
  description = "List of Yandex Cloud availability zones for deploying NAT instances"
  default = [
    "ru-central1-a",
    "ru-central1-b"
  ]
}