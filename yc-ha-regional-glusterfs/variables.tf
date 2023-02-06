# TYPE: ZONAL (better for performance) OR REGIONAL (for HA)

variable "is_ha" {
  type    = bool
  default = true
}

# NUMBER OF VM PER ZONE

variable "client_node_per_zone" {
  type        = number
  default     = 1
  description = "Number of client node per zone"
}

variable "storage_node_per_zone" {
  type        = number
  default     = 1
  description = "Number of storage node per zone"
}

# DISK OPTIONS

variable "disk_count_per_vm" {
  type        = number
  default     = 1
  description = "Number of additional disks for GlusterFS in each zone"
}

variable "disk_type" {
  type        = string
  default     = "network-ssd"
  description = "Type of GlusterFS disk"
}

variable "disk_size" {
  type        = number
  default     = 1024
  description = "Disk size GB"
}

variable "disk_block_size" {
  type        = number
  default     = 4096
  description = "Disk block size"
}

# CLIENT VM RESOURCES

variable "client_cpu_count" {
  type        = number
  default     = 4
  description = "Number of CPU in Storage Node"
}

variable "client_memory_count" {
  type        = number
  default     = 8
  description = "RAM (GB) size in Storage Node"
}

# STORAGE VM RESOURCES

variable "storage_cpu_count" {
  type        = number
  default     = 8
  description = "Number of CPU in Storage Node"
}

variable "storage_memory_count" {
  type        = number
  default     = 8
  description = "RAM (GB) size in Storage Node"
}

# SSH KEY

variable "local_pubkey_path" {
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
  description = "Local public key to access the client"
}
