# Kubernetes Master parameters
variable "folder_id" {
  description = "The ID of the folder that the Kubernetes cluster belongs to."
  type        = string
  default     = null
}

variable "network_id" {
  description = "The ID of the cluster network."
  type        = string
}

variable "master_region" {
  description = <<-EOF
    Name of the region where the cluster will be created. This setting is required for regional cluster and not used for zonal cluster.
  EOF
  type        = string
  default     = "ru-central1"
}

resource "random_string" "unique_id" {
  count   = var.unique_id == null ? 1 : 0
  length  = 8
  upper   = false
  lower   = true
  numeric = true
  special = false
}

variable "unique_id" {
  description = "User defined unique id."
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "Name of a specific Kubernetes cluster."
  type        = string
  default     = "k8s-cluster"
}

variable "description" {
  description = "Description of the Kubernetes cluster."
  type        = string
  default     = "Yandex Managed K8S cluster"
}

variable "cluster_version" {
  description = "Kubernetes cluster version"
  type        = string
  default     = null
}

variable "cluster_ipv4_range" {
  description = <<EOF
  CIDR block. IP range for allocating pod addresses.
  It should not overlap with any subnet in the network
  the Kubernetes cluster located in. Static routes will
  be set up for this CIDR blocks in node subnets.
  EOF
  type        = string
  default     = "172.17.0.0/16"
}

variable "cluster_ipv6_range" {
  description = "IPv6 CIDR block. IP range for allocating pod addresses."
  type        = string
  default     = null
}

variable "node_ipv4_cidr_mask_size" {
  description = <<EOF
    (Optional) Size of the masks that are assigned to each node in the cluster.
    This efficiently limits the maximum number of pods for each node.
  EOF
  type        = number
  default     = 24
}

variable "service_ipv4_range" {
  description = <<EOF
    CIDR block. IP range from which Kubernetes service cluster IP addresses 
    will be allocated from. It should not overlap with
    any subnet in the network the Kubernetes cluster located in
    EOF
  type        = string
  default     = "172.18.0.0/16"
}

variable "service_ipv6_range" {
  description = "IPv6 CIDR block. IP range for allocating pod addresses."
  type        = string
  default     = null
}

variable "service_account_name" {
  description = "IAM service account name."
  type        = string
  default     = "k8s-service-account"
}

variable "node_account_name" {
  description = "IAM node account name."
  type        = string
  default     = "k8s-node-account"
}

variable "release_channel" {
  description = "Kubernetes cluster release channel name"
  type        = string
  default     = "REGULAR"
  validation {
    condition     = contains(["STABLE", "RAPID", "REGULAR"], var.release_channel)
    error_message = "Release channel should be STABLE (stable feature set), RAPID (early bird feature access) and REGULAR."
  }
}

variable "network_policy_provider" {
  description = "Network policy provider for Kubernetes cluster"
  type        = string
  default     = "CALICO"
}

variable "enable_cilium_policy" {
  description = "Flag for enabling or disabling Cilium CNI."
  type        = bool
  default     = false
}

# Kubernetes Master node common parameters
variable "public_access" {
  description = "Public or private Kubernetes cluster"
  type        = bool
  default     = true
}

variable "allow_public_load_balancers" {
  description = "Flag for creating new IAM role with a load-balancer.admin access."
  type        = bool
  default     = true
}

variable "master_locations" {
  description = <<-EOF
    List of locations where the cluster will be created. If the list contains only one
    location, a zonal cluster will be created; if there are three locations, this will create a regional cluster.

    Note: The master locations list may only have ONE or THREE locations.
  EOF
  type = list(object({
    zone      = string
    subnet_id = string
  }))
  validation {
    condition     = contains([1, 3], length(var.master_locations))
    error_message = "Master locations list should have only one location for Zonal cluster and three locations for Regional!"
  }
}

variable "security_groups_ids_list" {
  description = "List of security group IDs to which the Kubernetes cluster belongs"
  type        = list(string)
  default     = []
  nullable    = true
}

variable "master_auto_upgrade" {
  description = "Boolean flag that specifies if master can be upgraded automatically."
  type        = bool
  default     = true
}
variable "master_maintenance_windows" {
  description = <<EOF
    List of structures that specifies maintenance windows,
    when auto update for the master is allowed.

    Example:
    ```
    master_maintenance_windows = [
      {
        day        = "monday"
        start_time = "23:00"
        duration   = "3h"
      }
    ]
    ```
  EOF
  type        = list(map(string))
  default     = []
}

variable "master_logging" {
  description = "(Optional) Master logging options."
  type        = map(any)
  default = {
    enabled                = true
    folder_id              = null
    enabled_kube_apiserver = true
    enabled_autoscaler     = true
    enabled_events         = true
  }
}

variable "master_labels" {
  description = "Set of key/value label pairs to assign Kubernetes master nodes."
  type        = map(string)
  default     = {}
}

variable "timeouts" {
  description = "Timeouts."
  type        = map(string)
  default = {
    create = "60m"
    update = "60m"
    delete = "60m"
  }
}
#
# Kubernetes Nodes Groups parameters
#
variable "node_groups" {
  description = <<EOF
    Kubernetes node groups map of maps. It could contain all parameters of yandex_kubernetes_node_group resource,
    many of them could be NULL and have default values.

    Notes:
     - If node groups version isn't defined, cluster version will be used instead of.
     - A master locations list must have only one location for zonal cluster and three locations for a regional.
     - All node groups are able to define own locations. These locations will be used at first.
     - If own location aren't defined for node groups with auto scale policy, locations for these groups will be automatically generated from master locations. If node groups list have more than three groups, locations for them will be assigned from the beggining of the master locations list. So, all node groups will be distributed in a range of master locations. 
     - Master locations will be used for fixed scale node groups.
     - Auto repair and upgrade values will be used master_auto_upgrade value.
     - Master maintenance windows will be used for Node groups also!
     - Only one max_expansion OR max_unavailable values should be specified for the deployment policy.
    
    Documentation - https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_node_group
    
    Default values:
    ```
      platform_id     = "standard-v3"
      node_cores      = 4
      node_memory     = 8
      node_gpus       = 0
      core_fraction   = 100
      disk_type       = "network-ssd"
      disk_size       = 32
      preemptible     = false
      nat             = false
      auto_repair     = true
      auto_upgrade    = true
      maintenance_day           = "monday"
      maintenance_start_time    = "20:00"
      maintenance_duration      = "3h30m"
      network_acceleration_type = "standard"
      container_runtime_type    = "containerd"
    ```

    Example:
    ```
      node_groups = {
        "yc-k8s-ng-01"  = {
          cluster_name  = "k8s-kube-cluster"
          description   = "Kubernetes nodes group with fixed scale policy and one maintenance window"
          fixed_scale   = {
            size = 3
          }
          labels        = {
            owner       = "yandex"
            service     = "kubernetes"
          }
          node_labels   = {
            role        = "worker-01"
            environment = "dev"
          }
        },
        "yc-k8s-ng-02"  = {
          description   = "Kubernetes nodes group with auto scale policy"
          auto_scale    = {
            min         = 2
            max         = 4
            initial     = 2
          }
          node_locations   = [
            {
              zone      = "ru-central1-b"
              subnet_id = "e2lu07tr481h35012c8p"
            }
          ]
          labels        = {
            owner       = "example"
            service     = "kubernetes"
          }
          node_labels   = {
            role        = "worker-02"
            environment = "testing"
          }
        }
      }
    ```
  EOF
  type        = any
  default     = {}
}
variable "node_groups_defaults" {
  description = "Map of common default values for Node groups."
  type        = object({
    platform_id   = optional(string, "standard-v3")
    node_cores    = optional(string, 4)
    node_memory   = optional(string, 8)
    node_gpus     = optional(string, 0)
    core_fraction = optional(string, 100)
    disk_type     = optional(string, "network-ssd")
    disk_size     = optional(string, "100")
    preemptible   = optional(bool, false)
    nat           = optional(bool, false)
    ipv4          = optional(bool, true)
    ipv6          = optional(bool, false)
    metadata      = optional(map(any), null)
  })
  default = {}
}
variable "network_acceleration_type" {
  description = "Network acceleration type for the Kubernetes node group"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "software_accelerated"], var.network_acceleration_type)
    error_message = "Type of network acceleration. Available values: standard, software_accelerated."
  }
}
variable "container_runtime_type" {
  description = "Kubernetes Node Group container runtime type"
  type        = string
  default     = "containerd"
  validation {
    condition     = contains(["docker", "containerd"], var.container_runtime_type)
    error_message = "Type of container runtime. Avaiable values: docker, containerd."
  }
}

# KMS key
variable "create_kms" {
  description = "Flag for enabling or disabling KMS key creation."
  type        = bool
  default     = true
}

variable "kms_key" {
  description = "KMS symmetric key parameters."
  type        = any
  default     = {}
}

# Security group
variable "enable_default_rules" {
  description = <<-EOF
    Manages creation of default security rules.

    Default security rules:
     - Allow all incoming traffic from any protocol.
     - Allows master-to-node and node-to-node communication inside a security group.
     - Allows pod-to-pod and service-to-service communication.
     - Allows debugging ICMP packets from internal subnets.
     - Allows incomming traffic from the Internet to the NodePort port range.
     - Allows all outgoing traffic. Nodes can connect to Yandex Container Registry, Yandex Object Storage, Docker Hub, etc.
     - Allow access to Kubernetes API via port 6443 from the subnet.
     - Allow access to Kubernetes API via port 443 from the subnet.
     - Allow access to worker nodes via SSH from the allowed IP range.
  EOF
  type        = bool
  default     = true
}

variable "custom_ingress_rules" {
  description = <<-EOF
    Map definition of custom security ingress rules.
    
    Example:
    ```
    custom_ingress_rules = {
      "rule1" = {
        protocol = "TCP"
        description = "rule-1"
        v4_cidr_blocks = ["0.0.0.0/0"]
        from_port = 3000
        to_port = 32767
      },
      "rule2" = {
        protocol = "TCP"
        description = "rule-2"
        v4_cidr_blocks = ["0.0.0.0/0"]
        port = 443
      },
      "rule3" = {
        protocol = "TCP"
        description = "rule-3"
        predefined_target = "self_security_group"
        from_port         = 0
        to_port           = 65535
      }
    }
    ```
  EOF
  type        = any
  default     = {}
}

variable "custom_egress_rules" {
  description = <<-EOF
    Map definition of custom security egress rules.
    
    Example:
    ```
    custom_egress_rules = {
      "rule1" = {
        protocol       = "ANY"
        description    = "rule-1"
        v4_cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
        from_port      = 8090
        to_port        = 8099
      },
      "rule2" = {
        protocol       = "UDP"
        description    = "rule-2"
        v4_cidr_blocks = ["10.0.1.0/24"]
        from_port      = 8090
        to_port        = 8099
      }
    }
    ```
  EOF
  type        = any
  default     = {}
}

variable "allowed_ips" {
  description = "List of allowed IPv4 CIDR blocks."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_ips_ssh" {
  description = "List of allowed IPv4 CIDR blocks for an access via SSH."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
