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

variable "yc_availability_zones" {
  type = list(string)
  description = "List of Yandex Cloud availability zones for deploying NAT instances"
  default = [
    "ru-central1-a",
    "ru-central1-b"
  ]
}

variable "subnet_prefix_list" {
  type        = list(string)
  description = "List of prefixes for NAT instances subnets. One prefix per availability zone in order: ru-central1-a, ru-central1-b, etc."
  default     = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
}

variable "nat_instances_count" {
  type = number
  description = "Number of NAT instances"
  default = 2
}

variable "bucket_private_access" {
  type        = bool
  description = "Restrict access to bucket only from NAT-instances public IP-address"
  default     = true
}

variable "bucket_console_access" {
  type        = bool
  description = "Allow access to bucket from Yandex Cloud console, apply if bucket_private_access = true"
  default     = true
}

variable "mgmt_ip" {
  type = string
  description = "Public IP address of workstation with Terraform to allow actions with bucket during Terraform deployment"
  default = null
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

