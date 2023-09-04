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

variable "zones" {
  type        = list(string)
  description = "zone list for deployment"
}

variable "network_id" {
  type        = string
  description = "Existing network_id(vpc-id) where resources will be created"
  default     = null
}

variable "network_name" {
  type        = string
  description = "Network name"
  default     = null
}

variable "network_description" {
  type        = string
  description = "Network description"
  default     = null
}

variable "k8s_security_group_create" {
  type        = bool
  description = "create security group for k8s cluster?"
  default     = true
}

variable "k8s_security_group_ids" {
  type        = list(string)
  description = "k8s cluster security group ids"
  default     = []
}

variable "k8s_cluster_name" {
  type        = string
  description = "Kubernetes cluster name"
  default     = "failure-test"
}

variable "k8s_node_username" {
  description = "A username for access to k8s nodes"
  type        = string
  default     = "ubuntu"
}

variable "k8s_node_pubkey_file" {
  description = "A public key filename for access to k8s nodes"
  type        = string
  default     = null
}

variable "k8s_node_pubkey" {
  description = "A public key for access to k8s nodes"
  type        = string
  default     = null
}

variable "k8s_cluster_version" {
  type        = string
  description = "Kubernetes cluster version"
  default     = "1.27"
}

variable "k8s_admin_name" {
  type        = string
  description = "Kubernetes cluster admin name"
  default     = "admin"
}

variable "k8s_static_kubeconfig" {
  type        = string
  description = "Path to static kubeconfig for cluster"
  default     = null
}

variable "k8s_workers_per_zone" {
  description = "Number of worker nodes per zone"
  type        = string
  default     = 2
}

variable "alb_setup" {
  type        = bool
  description = "Do the setup of ALB?"
  default     = true
}

variable "todoapp_setup" {
  type        = bool
  description = "Do the setup of todoapp?"
  default     = true
}

variable "todoapp_db" {
  type        = string
  description = "Database name for todoapp"
  default     = "todoapp"
}

variable "todoapp_owner" {
  type        = string
  description = "Database owner name for todoapp"
  default     = "todoapp"
}

variable "cert_id" {
  type        = string
  description = "todoapp certificat id"
}

variable "fqdn" {
  type        = string
  description = "todoapp domain name"
}

variable "todoapp_image_repository" {
  type        = string
  description = "todoapp image repository"
}

variable "todoapp_image_tag" {
  type        = string
  description = "todoapp image tag"
}

variable "todoapp_backend_count" {
  type        = string
  description = "todoapp frontend pods count"
  default     = 4
}

variable "todoapp_frontend_count" {
  type        = string
  description = "todoapp frontend pods count"
  default     = null
}

variable "ip_addr" {
  type        = string
  description = "alb ip address"
}

variable "chaos_mesh_setup" {
  type        = bool
  description = "Do the setup of chaos-mesh?"
  default     = true
}

variable "cr_id" {
  type        = string
  description = "registry for cluster"
  default     = null
}

variable "node_local_dns_setup" {
  type        = bool
  description = "Do the setup of node-local-dns?"
  default     = true
}

variable "name_suffix" {
  type        = string
  description = "SA name suffix for uniqueness"
  default     = null
}
