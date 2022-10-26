variable "create_vpc" {
  type        = bool
  default     = true
  description = "Create VCP object or not. If false existing vpc_id is required "
}

variable "vpc_id" {
  type        = string
  default     = null
  description = "Existing network_id(vpc-id) where resources be created"
}

variable "network_name" {
  description = "Prefix to be used on all the resources as identifier"
  type        = string
}

variable "network_description" {
  description = "An optional description of this resource. Provide this property when you create the resource."
  type        = string
  default     = "terraform-created"
}

variable "folder_id" {
  type        = string
  default     = null
  description = "Folder-ID where the resources will be created"
}

variable "public_subnets" {
  description = "Describe your public subnets preferences"
  type = list(object({
    zone           = string
    v4_cidr_blocks = string
  }))
  default = null
}

variable "private_subnets" {
  description = "Describe your private subnets preferences"
  type = list(object({
    zone           = string
    v4_cidr_blocks = string
  }))
  default = null
}
variable "routes_public_subnets" {
  description = "Describe your routes preferences for public subnets"
  type = list(object({
    destination_prefix = string
    next_hop_address   = string
  }))
  default = null
}
variable "routes_private_subnets" {
  description = "Describe your routes preferences for public subnets"
  type = list(object({
    destination_prefix = string
    next_hop_address   = string
  }))
  default = null
}
variable "domain_name" {
  type        = string
  default     = null
  description = "Domain name to be added to DHCP options"
}

variable "domain_name_servers" {
  type        = list(string)
  default     = []
  description = "Domain name servers to be added to DHCP options"
}
variable "ntp_servers" {
  type        = list(string)
  default     = []
  description = "NTP Servers for subnets"
}
variable "labels" {
  description = "A set of key/value label pairs to assign."
  type        = map(string)
  default     = null
}
