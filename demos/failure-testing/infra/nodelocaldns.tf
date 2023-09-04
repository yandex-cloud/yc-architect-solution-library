data "kubernetes_service_v1" "kube_dns" {
  metadata {
    name      = "kube-dns"
    namespace = "kube-system"
  }
  depends_on = [
    module.k8s_cluster
  ]
}

resource "helm_release" "node_local_dns" {
  count            = var.node_local_dns_setup ? 1 : 0
  name             = "node-local-dns"
  namespace        = "kube-system"
  repository       = "oci://cr.yandex/yc-marketplace/k8s.gcr.io/node-local-dns"
  chart            = "chart"
  version          = "1.5"
  create_namespace = false

  values = [<<-EOF
    config:
      cilium: false
      clusterIp: ${data.kubernetes_service_v1.kube_dns.spec.0.cluster_ip}
  EOF
  ]

  depends_on = [
    module.k8s_cluster
  ]
}

