locals {
  k8s_node_pubkey   = var.k8s_node_pubkey_file == null ? var.k8s_node_pubkey : file(var.k8s_node_pubkey_file)
  k8s_node_metadata = local.k8s_node_pubkey == null ? null : { "ssh-keys" : "${var.k8s_node_username}:${local.k8s_node_pubkey}" }
  k8s_master_zone   = element(var.zones, 0)
}

module "k8s_cluster" {
  #source = "git::https://github.com/terraform-yc-modules/terraform-yc-kubernetes"
  source = "../modules/terraform-yc-kubernetes"

  cluster_name         = var.k8s_cluster_name
  cluster_version      = var.k8s_cluster_version
  release_channel      = "RAPID"
  folder_id            = local.folder_id
  network_id           = local.network_id
  public_access        = true
  create_kms           = true
  enable_cilium_policy = false
  cluster_ipv4_range   = "10.208.0.0/16"
  service_ipv4_range   = "10.224.0.0/16"
  service_account_name = "${var.k8s_cluster_name}-service-account"
  node_account_name    = "${var.k8s_cluster_name}-node-account"
  unique_id            = var.name_suffix

  master_locations = [{
    zone      = module.network.subnets["k8s-${local.k8s_master_zone}"].zone
    subnet_id = module.network.subnets["k8s-${local.k8s_master_zone}"].id
  }]

  master_maintenance_windows = [{
    day        = "saturday"
    start_time = "04:00"
    duration   = "2h"
  }]

  node_groups_defaults = {
    node_cores             = 4
    node_memory            = 8
    disk_type              = "network-ssd-nonreplicated"
    disk_size              = 93
    preemptible            = false
    maintenance_day        = "sunday"
    maintenance_start_time = "04:00"
    maintenance_duration   = "2h"
    metadata               = local.k8s_node_metadata
  }

  node_groups = merge({
    "system" = {
      description = "System node group"
      node_cores  = 2
      node_memory = 4
      fixed_scale = {
        size = 2
      }
      node_locations = [{
        zone      = module.network.subnets["k8s-${local.k8s_master_zone}"].zone
        subnet_id = module.network.subnets["k8s-${local.k8s_master_zone}"].id
      }]
      #      node_taints = [ "CriticalAddonsOnly=:NoSchedule" ]
    } },
    { for zone in var.zones : "ft-${zone}" => {
      description = "Failure testing workers in ${zone}"
#      auto_scale = {
#        initial = var.k8s_workers_per_zone
#        min     = var.k8s_workers_per_zone
#        max     = 3
#      }
      fixed_scale = {
        size = var.k8s_workers_per_zone
      }
      node_locations = [{
        zone      = module.network.subnets["k8s-${zone}"].zone
        subnet_id = module.network.subnets["k8s-${zone}"].id
      }]
      node_taints = ["FailureTesting=:NoSchedule"]
      node_labels = {
        "failure-testing" = "true"
      }
      preemptible = true
    } }
  )
}

data "yandex_kubernetes_cluster" "k8s_cluster" {
  folder_id  = local.folder_id
  cluster_id = module.k8s_cluster.cluster_id
}

resource "yandex_container_registry_iam_binding" "cr_pusher" {
  count       = var.cr_id == null ? 0 : 1
  registry_id = var.cr_id
  role        = "container-registry.images.puller"

  members = [
    "serviceAccount:${data.yandex_kubernetes_cluster.k8s_cluster.node_service_account_id}",
  ]
}

resource "kubernetes_service_account_v1" "admin" {
  count = var.k8s_static_kubeconfig == null ? 0 : 1
  metadata {
    name      = var.k8s_admin_name
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding_v1" "cluster_admin" {
  metadata {
    name = "${kubernetes_service_account_v1.admin.0.metadata.0.name}-cluster-admin"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.admin.0.metadata.0.name
    namespace = kubernetes_service_account_v1.admin.0.metadata.0.namespace
  }
}

