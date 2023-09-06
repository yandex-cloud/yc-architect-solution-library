terraform {
  required_version = ">= 1.0.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "> 0.8"
    }

    random = {
      source  = "hashicorp/random"
      version = "> 3.3"
    }
    time = {
      source  = "hashicorp/time"
      version = "> 0.9"
    }
  }
}
