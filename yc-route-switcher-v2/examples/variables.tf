// folder id for resources
variable "folder_id" {
  type = string
  default = null
}

// VPC name for resources
variable "vpc_name" {
  type = string
  default = null
}

// list of trusted public IP addresses for connection to NAT-instances 
variable "trusted_ip_for_mgmt" {
  type = list(string)
  default = null
}

// username for VMs
variable "vm_username" {
   type = string
   default = null
}

// private subnets
variable "private_subnet_a_name" {
   type = string
   default = null
}

variable "private_subnet_a_cidr" {
   type = string
   default = null
}

// public subnets
variable "public_subnet_a_name" {
   type = string
   default = null
}

variable "public_subnet_b_name" {
   type = string
   default = null
}

variable "public_subnet_a_cidr" {
   type = string
   default = null
}

variable "public_subnet_b_cidr" {
   type = string
   default = null
}