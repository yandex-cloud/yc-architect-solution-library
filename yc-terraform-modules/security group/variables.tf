
variable "vpc_id" {
  type        = string
  default     = null
  description = "Existing network_id(vpc-id) where resource be created"
}
variable "name" {
  type        = string
  description = "SG name"
}
variable "folder_id" {
  type        = string
  default     = null
  description = "Folder-ID where the resources will be created"
}
variable "labels" {
  description = "A set of key/value label pairs to assign."
  type        = map(string)
  default     = null
}

variable "ingress_rules_with_cidrs" {
  type        = any
  description = <<EOT
  SG rules with CIDRs as source.
  Example:
  
  ingress_rules_with_cidrs = [
  {
    description    = "ssh"
    port           = 22
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  },
  {
    description    = "ICMP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  },
  ]
  EOT
}
variable "ingress_rules_with_sg_ids" {
  type        = any
  description = <<EOT
  SG rules with other SG-id as source.
  Example:

  ingress_rules_with_sg_ids = [
  {
    protocol          = "ANY"
    description       = "Communication with web SG"
    security_group_id = "xxx222xxx"
  },
]
  EOT
}

variable "self" {
  type        = bool
  description = "Is SG allow communicate"
  default     = true
}
variable "self_port" {
  type        = number
  description = "allows communication within security group with port"
  default     = null
}
variable "self_from_port" {
  type        = number
  description = "allows communication within security group with port from"
  default     = null
}
variable "self_to_port" {
  type        = number
  description = "allows communication within security group with port to"
  default     = null
}
variable "self_protocol" {
  type        = string
  description = "allows communication within security group with protocol"
  default     = "ANY"
}
variable "egress_rules" {
  type        = any
  description = <<EOT
  SG egress rules with CIDRS.
  Example:

  egress_rules = [
  {
    protocol       = "ANY"
    description    = "To the internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
  },
]
  EOT
}
