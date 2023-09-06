locals {
  alb_subnets = join(",", [for zone in var.zones : module.network.subnets["k8s-${zone}"].id])
}

resource "yandex_iam_service_account" "k8s_cluster_alb" {
  count       = var.alb_setup ? 1 : 0
  name        = "k8s-cluster-alb${local.name_suffix}"
  description = "service account for alb ingress controller"
  folder_id   = local.folder_id
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_cluster_alb" {
  for_each  = toset(var.alb_setup ? ["alb.editor", "vpc.publicAdmin", "certificate-manager.certificates.downloader", "compute.viewer"] : [])
  folder_id = local.folder_id

  role   = each.key
  member = "serviceAccount:${yandex_iam_service_account.k8s_cluster_alb[0].id}"
}

resource "yandex_iam_service_account_key" "k8s_cluster_alb" {
  count              = var.alb_setup ? 1 : 0
  service_account_id = yandex_iam_service_account.k8s_cluster_alb[0].id
  description        = "k8s cluster alb sa key"
  key_algorithm      = "RSA_2048"
}

resource "kubernetes_namespace" "alb_ingress" {
  count = var.alb_setup ? 1 : 0
  metadata {
    name = "alb-ingress"
  }
}

resource "kubernetes_secret" "yc_alb_ingress_controller_sa_key" {
  count = var.alb_setup ? 1 : 0
  metadata {
    name      = "yc-alb-ingress-controller-sa-key"
    namespace = "alb-ingress"
  }
  data = {
    "sa-key.json" = jsonencode(
      {
        "id" : yandex_iam_service_account_key.k8s_cluster_alb[0].id,
        "service_account_id" : yandex_iam_service_account_key.k8s_cluster_alb[0].service_account_id,
        "created_at" : yandex_iam_service_account_key.k8s_cluster_alb[0].created_at,
        "key_algorithm" : yandex_iam_service_account_key.k8s_cluster_alb[0].key_algorithm,
        "public_key" : yandex_iam_service_account_key.k8s_cluster_alb[0].public_key,
        "private_key" : yandex_iam_service_account_key.k8s_cluster_alb[0].private_key
      }
    )
  }

  type = "kubernetes.io/Opaque"
  depends_on = [
    kubernetes_namespace.alb_ingress[0]
  ]
}

resource "helm_release" "alb_ingress" {
  count            = var.alb_setup ? 1 : 0
  name             = "alb-ingress"
  namespace        = "alb-ingress"
  repository       = "oci://cr.yandex/yc-marketplace/yandex-cloud/yc-alb-ingress"
  chart            = "yc-alb-ingress-controller-chart"
  version          = "v0.1.22"
  create_namespace = true

  values = [<<-EOF
    folderId: ${local.folder_id}
    clusterId: ${module.k8s_cluster.cluster_id}
    daemonsetTolerations:
      - operator: Exists
  EOF
  ]

  depends_on = [
    module.k8s_cluster,
    yandex_resourcemanager_folder_iam_member.k8s_cluster_alb,
    yandex_iam_service_account_key.k8s_cluster_alb,
    kubernetes_namespace.alb_ingress[0],
    kubernetes_secret.yc_alb_ingress_controller_sa_key[0]
  ]
}

resource "yandex_vpc_security_group" "alb" {
  name        = "k8s-alb${local.name_suffix}"
  description = "alb security group"
  network_id  = local.network_id
  folder_id   = local.folder_id

  ingress {
    protocol       = "ICMP"
    description    = "ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "http"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "https"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  ingress {
    protocol          = "TCP"
    description       = "Rule allows availability checks from load balancer's address range. It is required for a db cluster"
    predefined_target = "loadbalancer_healthchecks"
    from_port         = 0
    to_port           = 65535
  }

  ingress {
    protocol          = "ANY"
    description       = "Rule allows master and slave communication inside a security group."
    predefined_target = "self_security_group"
    from_port         = 0
    to_port           = 65535
  }

  egress {
    protocol    = "TCP"
    description = "Enable traffic from ALB to K8s services"
    #    predefined_target = "self_security_group"
    v4_cidr_blocks = flatten([for subnet in module.network.subnets : subnet.v4_cidr_blocks if startswith(subnet.name, "k8s-")])
    from_port      = 30000
    to_port        = 65535
  }

  egress {
    protocol       = "TCP"
    description    = "Enable probes from ALB to K8s"
    v4_cidr_blocks = flatten([for subnet in module.network.subnets : subnet.v4_cidr_blocks if startswith(subnet.name, "k8s-")])
    port           = 10501
  }
}

