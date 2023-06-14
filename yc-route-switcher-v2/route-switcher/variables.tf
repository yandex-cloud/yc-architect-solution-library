variable "start_module" {
  description = "Used to start operation of module (actually to create route-switcher timer trigger)"
  type        = bool
  default     = false
}

variable "folder_id" {
  description = "Folder id for route-switcher infrastructure"
  type        = string
  default     = null
}

variable "route_table_folder_list" {
  description = "List of folders id with route tables protected by route-switcher"
  type        = list(string)
  default     = []
}

variable "route_table_list" {
    description = "List of route tables id which are protected by route-switcher"
    type = list(string)
    default     = []
}

variable "router_healthcheck_port" {
  description = "Healthchecked tcp port of routers"
  type        = number
  default     = null
}

variable "back_to_primary" {
  description = "Back to primary router after its recovery"
  type        = bool
  default     = true
}

variable "routers" {
  description = "List of routers. For each router specify its healtchecked ip address with subnet, list of router interfaces with ip addresses used as next hops in route tables and corresponding backup peer router ip adresses."
  type = list(object({
    healthchecked_ip = string  # ip address which will be checked by NLB to obtain router status. Usually located in management network.
    healthchecked_subnet_id = string # subnet id of healthchecked ip address
    interfaces = list(object({
      own_ip = string           # ip address of router interface
      backup_peer_ip = string   # ip address of backup router, which will be used to switch next hop for a static route in case of a router failure
    })) 
  }))
  default = []
}

variable "route_switcher_sa_roles" {
  description = "Roles that are needed for route-switcher service account"
  type        = list(string)
  default = ["load-balancer.privateAdmin", "storage.editor", "serverless.functions.invoker", "storage.uploader"]
}

variable "cron_interval" {
  description = "Retrying interval in seconds used in function logs for failed requests. Should be equal cron interval for function."
  type = number
  default = 60
}