# ==================================
# Terraform & Provider Configuration
# ==================================

terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.85.0"
    }
    local = {
      source = "hashicorp/local"
      version = "~> 2.3.0"
    }
    null = {
      source = "hashicorp/null"
      version = "~> 3.2.1"
    }
  }
}
