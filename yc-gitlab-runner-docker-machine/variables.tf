variable "cloud_id" {
  type        = string
  description = "cloud-id"
  default     = null
}

variable "folder_id" {
  type        = string
  description = "folder-id"
  default     = null
}

variable "network_create" {
  type        = bool
  description = "create the network?"
  default     = true
}

variable "security_group_create" {
  type        = bool
  description = "create security group(s)?"
  default     = true
}

variable "network_id" {
  type        = string
  description = "Existing network_id(vpc-id) where resources will be created"
  default     = null
}

variable "network_name" {
  type        = string
  description = "Network name"
  default     = "docker-machine"
}

variable "network_description" {
  type        = string
  description = "Network description"
  default     = "autocreated docker-machine network"
}

variable "network_cidr" {
  type        = string
  description = "network cidr"
  default     = "10.11.12.0/24"
}

variable "subnet_id" {
  type        = string
  description = "Existing subnet id"
  default     = null
}

variable "default_zone" {
  type        = string
  description = "Default availability zone"
  default     = "ru-central1-a"
}

variable "default_region" {
  type        = string
  description = "Default Yandex Cloud region"
  default     = "ru-central1"
}

variable "purpose" {
  type        = string
  description = "Virtual machine purpose (prod, dev, stage, etc)"
  default     = "docker-machine"
}

variable "username" {
  type        = string
  description = "Initialzation username"
  default     = "ubuntu"
}

variable "user_pubkey_filename" {
  description = "ssh public key filename"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "gitlab_url" {
  type        = string
  description = "gitlab url"
}

variable "gitlab_registration_token" {
  type        = string
  description = "gitlab registration token"
}

variable "gitlab_runner_tags" {
  type        = string
  description = "gitlab runner tags"
  default     = ""
}

variable "worker_runners_limit" {
  type        = string
  description = "Maximum number of parallel workers"
  default     = "10"
}

variable "worker_use_internal_ip" {
  type        = bool
  description = "yandex-use-internal-ip"
  default     = true
}

variable "worker_image_family" {
  type        = string
  description = "yandex-image-family"
  default     = "ubuntu-2204-lts"
}

variable "worker_image_id" {
  type        = string
  description = "yandex-image-id"
  default     = null
}

variable "worker_cores" {
  type        = string
  description = "yandex-cores"
  default     = "4"
}

variable "worker_disk_type" {
  type        = string
  description = "yandex-disk-type"
  default     = "network-ssd-nonreplicated"
}

variable "worker_disk_size" {
  type        = string
  description = "yandex-disk-size"
  default     = "93"
}

variable "worker_memory" {
  type        = string
  description = "yandex-memory"
  default     = "8"
}

variable "worker_preemptible" {
  type        = bool
  description = "yandex-preemptible"
  default     = true
}

variable "worker_platform_id" {
  type        = string
  description = "yandex-platform-id"
  default     = "standard-v3"
}


