variable "folder_id" {
  type = string
}

variable "client_node_per_zone" {
  type    = number
  default = 10
}

variable "create_clients" {
  type    = bool
  default = true
}

# CLIENT VM RESOURCES

variable "client_cpu_count" {
  type        = number
  default     = 40
  description = "Number of CPU in Storage Node"
}

variable "client_memory_count" {
  type        = number
  default     = 120
  description = "RAM (GB) size in Storage Node"
}

variable "is_regional" {
  type    = bool
  default = false
}

variable "juicefs_bucket_name" {
  type = string
}

variable "redis_pwd" {
  type      = string
  sensitive = true
}

# SSH KEY

variable "local_pubkey_path" {
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
  description = "Local public key to access the client"
}
