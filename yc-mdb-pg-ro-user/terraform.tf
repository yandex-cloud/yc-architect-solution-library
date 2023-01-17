terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
    postgresql = {
      source = "cyrilgdn/postgresql"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-b"
}
