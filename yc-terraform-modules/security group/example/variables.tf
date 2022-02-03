
variable "vpc_id" {
  type        = string
  default     = null
  description = "Existing network_id(vpc-id) where resource be created"
}
variable "security_groups" {
  type = any
}

