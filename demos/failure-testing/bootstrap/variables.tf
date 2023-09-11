variable "cloud_id" {
  type        = string
  description = "cloud-id"
  default     = null
}

variable "folder_create" {
  type        = bool
  description = "Do folder creation?"
  default     = false
}

variable "folder_id" {
  type        = string
  description = "folder-id"
  default     = null
}

variable "uniq_names" {
  type        = bool
  description = "Make names unique?"
  default     = true
}

variable "folder_name" {
  type        = string
  description = "folder name"
  default     = null
}

variable "folder_description" {
  type        = string
  description = "folder description"
  default     = "Failure testing playground"
}

variable "ft_sa_id" {
  type        = string
  description = "id of the existing serivce account for failure-testing"
  default     = null
}

variable "ft_sa_name" {
  type        = string
  description = "failure-testing service account name"
  default     = "failure-testing"
}

variable "ft_sa_description" {
  type        = string
  description = "failure-testing service account description"
  default     = "failure testing infrastructure"
}

variable "network_id" {
  type        = string
  description = "Existing network_id(vpc-id) where resources will be created"
  default     = null
}

variable "network_name" {
  type        = string
  description = "Network name"
  default     = "failure-test"
}

variable "network_description" {
  type        = string
  description = "Network description"
  default     = "Faiure testing"
}

variable "ip_addr" {
  type        = string
  description = "ip address"
  default     = null
}

variable "ip_addr_name" {
  type        = string
  description = "ip address"
  default     = "fail-testing"
}

variable "ip_addr_zone" {
  type        = string
  description = "ip address zone (for new addresses)"
  default     = "ru-central1-a"
}

variable "dns_zone_id" {
  type        = string
  description = "dns_zone_id"
  default     = null
}

variable "dns_domain" {
  type        = string
  description = "dns domain"
  default     = null
}

variable "dns_hostnames" {
  type        = list(string)
  description = "dns hostnames"
  default     = []
}

variable "dns_wildcard_enable" {
  type        = bool
  description = "add wildcard recornd to dns zone?"
  default     = true
}

variable "cr_id" {
  type        = string
  description = "existing cr id"
  default     = null
}

variable "cr_name" {
  type        = string
  description = "cr name"
  default     = "fail-testing"
}

variable "cr_folder_id" {
  type        = string
  description = "cr folder id if it differs form current folder id"
  default     = null
}

variable "cr_sa_name" {
  type        = string
  description = "cr service account name"
  default     = null
}

variable "cr_sa_description" {
  type        = string
  description = "cr service account description"
  default     = "cr pusher service account for fail testing"
}

variable "cr_sa_key_filename" {
  type        = string
  description = "cr service account key file name"
  default     = null
}

variable "gitlab_env_vars_setup" {
  type        = bool
  description = "Do the setup of gitlab project variables?"
  default     = true
}

variable "gitlab_runner_enabled" {
  type        = bool
  description = "Do the setup of gitlab runner?"
  default     = false
}

variable "gitlab_enabled" {
  type        = bool
  description = "Do the setup of gitlab repo?"
  default     = true
}

variable "gitlab_url" {
  type        = string
  description = "gitlab server url"
  default     = null
}

variable "gitlab_project_id" {
  type        = string
  description = "gitlab repo project_id"
  default     = null
}

variable "gitlab_project_name" {
  type        = string
  description = "gitlab project name"
  default     = "failure-testing"
}

variable "gitlab_username" {
  type        = string
  description = "gitlab username with at least maintainer role"
  default     = null
}

variable "gitlab_access_token" {
  type        = string
  description = "gitlab access_token with 'api' permission"
  default     = null
}
