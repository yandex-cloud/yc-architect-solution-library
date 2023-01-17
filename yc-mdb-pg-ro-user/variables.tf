variable "create_vpc" {
  type        = bool
  default     = true
  description = "Create VCP object or use existent. If false vpc_id is required "
}

variable "vpc_id" {
  type        = string
  default     = null
  description = "VPC id"
}

variable "create_subnet" {
  type        = bool
  default     = true
  description = "Create subnet object or use existent. If false existing subnet_id is required "
}

variable "subnet_id" {
  type        = string
  default     = null
  description = "subnet id"
}

variable "subnet_v4_cidr_block" {
  type        = string
  default     = "192.168.127.0/24"
  description = "Subnet cidr"
}

variable "create_sg" {
  type        = bool
  default     = true
  description = "Create secrutiy group object(s) otherwise don't use it"
}

variable "sg_id" {
  type        = string
  default     = null
  description = "security group id"
}

variable "folder_id" {
  type        = string
  description = "Folder id where the resources will be created"
}

variable "cloud_id" {
  type        = string
  description = "cloud id where the resources will be created"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "AZ id where the resources will be created"
}

variable "user_owner_passwd" {
  type        = string
  description = "Password for user_owner"
}

variable "user_ro_passwd" {
  type        = string
  description = "Password for user_ro"
}


