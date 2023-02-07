//-------------id for cloud in Yandex Cloud
variable "cloud_id" {
  default = null
}

//-------------TCP port used for public application published in DMZ
variable "public_app_port" {
  default     = null 
}
//-------------and corresponding internal port for the same application
variable "internal_app_port" {
  default     = null 
}

//-------------Define list of trusted public IP addresses for connection to Jump VM 
variable "trusted_ip_for_access_jump-vm" {
  type = list(string)
  default = null
}

//-------------Jump VM Wireguard settings
variable "wg_port" {
  default     = null 
}
variable "wg_client_dns" { 
   default = null
}
variable "jump_vm_admin_username" {
   default = null
}

//------------VPC List

//--VPC 1-- DMZ
variable "vpc_name_1" {
  default     = null 
}
variable "subnet-a_vpc_1" {
  default = null 
}
variable "subnet-b_vpc_1" {
  default = null 
}

//--VPC 2-- app
variable "vpc_name_2" {
  default     = null
}
variable "subnet-a_vpc_2" {
  default = null
}
variable "subnet-b_vpc_2" {
  default = null
}

//--VPC 3-- public
variable "vpc_name_3" {
  default     = null
}
variable "subnet-a_vpc_3" {
  default = null
}
variable "subnet-b_vpc_3" {
  default = null
}

//--VPC 4-- management
variable "vpc_name_4" {
  default     = null
}
variable "subnet-a_vpc_4" {
  default = null
}
variable "subnet-b_vpc_4" {
  default = null
}

//--VPC 5-- database
variable "vpc_name_5" {
  default     = null
}
variable "subnet-a_vpc_5" {
  default = null
}
variable "subnet-b_vpc_5" {
  default = null
}


//-----------Additional VPC List (for the future because you can't add interfaces after VM creation)

//--VPC 6--
variable "vpc_name_6" {
  default     = null
}
variable "subnet-a_vpc_6" {
  default = null
}
variable "subnet-b_vpc_6" {
  default = null
}

//--VPC 7--
variable "vpc_name_7" {
  default     = null
}
variable "subnet-a_vpc_7" {
  default = null
}
variable "subnet-b_vpc_7" {
  default = null
}

//--VPC 8--
variable "vpc_name_8" {
  default     = null
}
variable "subnet-a_vpc_8" {
  default = null
}
variable "subnet-b_vpc_8" {
  default = null
}