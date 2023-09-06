locals {
  db_user_map = merge(
    { for u in module.db.users_data : u.user => u },
    { for u in module.db.owners_data : u.user => u }
  )
}

resource "kubernetes_namespace" "todoapp" {
  count = var.todoapp_setup ? 1 : 0
  metadata {
    name = "todoapp"
  }
  depends_on = [
    resource.null_resource.infra
  ]
}

resource "kubernetes_secret" "todobackend" {
  count = var.todoapp_setup ? 1 : 0
  metadata {
    name      = "todobackend"
    namespace = kubernetes_namespace.todoapp[0].metadata[0].name
  }
  data = {
    "db_url" = "postgresql://${var.todoapp_owner}:${urlencode(local.db_user_map[var.todoapp_owner].password)}@c-${module.db.cluster_id}.rw.mdb.yandexcloud.net:6432/${var.todoapp_db}"
  }

  type = "kubernetes.io/Opaque"
  depends_on = [
    kubernetes_namespace.todoapp[0]
  ]
}


resource "helm_release" "todobackend" {
  count      = var.todoapp_setup ? 1 : 0
  name       = "todobackend"
  namespace  = kubernetes_namespace.todoapp[0].metadata[0].name
  repository = "../deploy/charts/"
  chart      = "backend"
  #  version    = ""
  create_namespace = true
  values = [<<-EOF
    replicaCount: ${var.todoapp_backend_count == null ? length(var.zones) : var.todoapp_backend_count}
    
    image:
      repository: "${var.todoapp_image_repository}/todo/backend"
      tag: "${var.todoapp_image_tag}"
      pullPolicy: IfNotPresent

    env:
      - name: DATABASE_URL
        valueFrom:
          secretKeyRef:
            name: todobackend
            key: db_url

    tolerations:
      - key: FailureTesting
        operator: Exists

    topologySpreadConstraints:
      - topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule
        maxSkew: 1
      - topologyKey: kubernetes.io/zone
        whenUnsatisfiable: ScheduleAnyway
        maxSkew: 1

    nodeSelector:
      failure-testing: "true"

    service:
      externalTrafficPolicy: Local
      type: NodePort
      port: 80

    ingress:
      enabled: true
      className: ""
      annotations:
        ingress.alb.yc.io/group-name: ingress
        ingress.alb.yc.io/subnets: "${local.alb_subnets}"
        ingress.alb.yc.io/external-ipv4-address: "${var.ip_addr}"
        ingress.alb.yc.io/security-groups: ${yandex_vpc_security_group.alb.id}
        ingress.alb.yc.io/request-timeout: 10s
        ingress.alb.yc.io/idle-timeout: 180s
      hosts:
        - host: ${var.fqdn}
          paths:
            - path: /api/
              pathType: Prefix
      tls:
        - secretName: yc-certmgr-cert-id-${var.cert_id}
          hosts:
            - ${var.fqdn}
  EOF
  ]

  depends_on = [
    resource.null_resource.infra,
    kubernetes_secret.todobackend
  ]
  timeout = 600
  wait    = false
}

resource "helm_release" "todofrontend" {
  count      = var.todoapp_setup ? 1 : 0
  name       = "todofrontend"
  namespace  = kubernetes_namespace.todoapp[0].metadata[0].name
  repository = "../deploy/charts/"
  chart      = "frontend"
  #  version    = ""
  create_namespace = true
  values = [<<-EOF
    replicaCount: ${var.todoapp_frontend_count == null ? length(var.zones) : var.todoapp_frontend_count}
    
    image:
      repository: "${var.todoapp_image_repository}/todo/frontend"
      tag: "${var.todoapp_image_tag}"
      pullPolicy: IfNotPresent

    service:
      externalTrafficPolicy: Local
      type: NodePort
      port: 80

    tolerations:
      - key: FailureTesting
        operator: Exists

    nodeSelector:
      failure-testing: "true"

    topologySpreadConstraints:
      - topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule
        maxSkew: 1
      - topologyKey: kubernetes.io/zone
        whenUnsatisfiable: ScheduleAnyway
        maxSkew: 1

    ingress:
      enabled: true
      className: ""
      annotations:
        ingress.alb.yc.io/group-name: ingress
        ingress.alb.yc.io/subnets: "${local.alb_subnets}"
        ingress.alb.yc.io/external-ipv4-address: "${var.ip_addr}"
        ingress.alb.yc.io/security-groups: ${yandex_vpc_security_group.alb.id}
      hosts:
        - host: ${var.fqdn}
          paths:
            - path: /
              pathType: Prefix
      tls:
        - secretName: yc-certmgr-cert-id-${var.cert_id}
          hosts:
            - ${var.fqdn}
  EOF
  ]

  depends_on = [
    resource.null_resource.infra
  ]

  timeout = 600
  wait    = false
}

