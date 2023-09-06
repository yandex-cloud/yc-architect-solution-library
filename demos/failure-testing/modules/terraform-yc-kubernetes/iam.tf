locals {
  iam_defaults = {
    service_account_name = "k8s-service-account${local.unique_id}"
    node_account_name    = "k8s-node-account${local.unique_id}"
  }
}

resource "yandex_iam_service_account" "master" {
  folder_id = local.folder_id
  name      = try("${var.service_account_name}${local.unique_id}", local.iam_defaults.service_account_name)
}

resource "yandex_iam_service_account" "node_account" {
  folder_id = local.folder_id
  name      = try("${var.node_account_name}${local.unique_id}", local.iam_defaults.node_account_name)
}

resource "yandex_resourcemanager_folder_iam_member" "sa_calico_network_policy_role" {
  count     = var.enable_cilium_policy ? 0 : 1
  folder_id = local.folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.master.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "sa_cilium_network_policy_role" {
  count     = var.enable_cilium_policy ? 1 : 0
  folder_id = local.folder_id
  role      = "k8s.tunnelClusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.master.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "sa_node_group_public_role_admin" {
  count     = lookup(var.node_groups, "nat", true) ? 1 : 0
  folder_id = local.folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.master.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "sa_node_group_loadbalancer_role_admin" {
  count     = lookup(var.node_groups, "nat", true) ? 1 : 0
  folder_id = local.folder_id
  role      = "load-balancer.admin"
  member    = "serviceAccount:${yandex_iam_service_account.master.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "sa_public_loadbalancers_role" {
  count     = var.allow_public_load_balancers ? 1 : 0
  folder_id = local.folder_id
  role      = "load-balancer.admin"
  member    = "serviceAccount:${yandex_iam_service_account.master.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "sa_logging_writer_role" {
  count     = var.master_logging.enabled ? 1 : 0
  folder_id = local.folder_id
  role      = "logging.writer"
  member    = "serviceAccount:${yandex_iam_service_account.master.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "node_account" {
  folder_id = local.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.node_account.id}"
}
