provider "helm" {
  debug = true
  kubernetes {
    host                   = module.k8s_cluster.external_v4_endpoint
    cluster_ca_certificate = module.k8s_cluster.cluster_ca_certificate
    token                  = data.yandex_client_config.client.iam_token
  }
  registry {
    url      = "oci://cr.yandex"
    username = "iam"
    password = data.yandex_client_config.client.iam_token
  }
}

provider "kubernetes" {
  host                   = module.k8s_cluster.external_v4_endpoint
  cluster_ca_certificate = module.k8s_cluster.cluster_ca_certificate
  token                  = data.yandex_client_config.client.iam_token
}

