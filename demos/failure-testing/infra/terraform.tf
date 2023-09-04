terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0.0"
    }
  }

  backend "http" {
  }

  required_version = ">= 0.13"
}
