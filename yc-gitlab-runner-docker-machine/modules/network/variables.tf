variable "cloud_id" {
  type = string
  description = "cloud-id"
}

variable "folder_id" {
  type = string
  description = "folder-id"
}

variable "folders" {
  description = "folders map (for multifolder networks)"
  type = map(object({id = string}))
  default = null
}

variable "network_create" {
  type = bool
  description = "Have to create network?"
  default = true
}

variable "network_id" {
  type = string
  default = null
  description = "Existing network_id(vpc-id) where resources be created"
}

variable "network_name" {
  description = "Network name"
  type = string
}

variable "network_description" {
  description = "Network description"
  type = string
  default = "main"
}

variable "domain_name" {
  description = "Default local domain name"
  type = string
  default = null
}

variable "domain_name_servers" {
  type = list(string)
  default = []
  description = "Domain name servers to be added to DHCP options"
}

variable "ntp_servers" {
  type = list(string)
  default = []
  description = "NTP Servers for subnets"
}

variable "gateway_id" {
  type = string
  description = "gateway-id"
  default = null
}

variable "subnets" {
  description = "subnets"
  type = list(object({
    purpose = string
    zone = string
    v4_cidr_blocks = string
    folder_name = optional(string, null)
    route_table = optional(string, null)
  }))
  default = null
}

variable "route_tables" {
  description = "Describe your routes"
  type = list(object({ 
    name = string
    routes = list(object ({
      destination_prefix = string
      next_hop_address = string
    })) 
  }))
  default = null
}

variable "labels" {
  description = "A labels for resources"
  type = map(string)
  default = null
}

