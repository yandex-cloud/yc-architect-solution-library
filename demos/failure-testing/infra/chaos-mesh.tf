
resource "kubernetes_namespace" "chaos_mesh" {
  count = var.chaos_mesh_setup ? 1 : 0
  metadata {
    name = "chaos-mesh"
  }
  depends_on = [
    resource.null_resource.infra
  ]
}

resource "helm_release" "chaos_mesh" {
  count     = var.chaos_mesh_setup ? 1 : 0
  name      = "chaos-mesh"
  namespace = kubernetes_namespace.chaos_mesh[0].metadata[0].name
  #  repository = "oci://cr.yandex/yc-marketplace/yandex-cloud/chaos-mesh"
  #  chart      = "chaos-mesh"
  #  version    = "2.6.1-1b"
  repository = "https://charts.chaos-mesh.org"
  chart      = "chaos-mesh"

  create_namespace = true
  values = [<<-EOF
    controllerManager:
      replicaCount: 1
    chaosDaemon:
      tolerations:
        - operator: Exists
      runtime: containerd 
      socketPath: /run/containerd/containerd.sock
    dashboard:
      ingress:
        enabled: true
    
        annotations:
          ingress.alb.yc.io/group-name: ingress
          ingress.alb.yc.io/subnets: "${local.alb_subnets}"
          ingress.alb.yc.io/external-ipv4-address: "${var.ip_addr}"
          ingress.alb.yc.io/security-groups: ${yandex_vpc_security_group.alb.id}
    
        hosts:
          - name: cm-${var.fqdn}
            tls: true
            tlsSecret: yc-certmgr-cert-id-${var.cert_id}
  EOF
  ]

  depends_on = [
    resource.null_resource.infra
  ]
}

