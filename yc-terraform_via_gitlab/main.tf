terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = ">=0.97"
    }
  }
  required_version = ">=1.5.6"
    backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "<bucket_name>"
    region     = "ru-central1"
    key        = "<path/to/terraform.tfstate>"
    access_key = var.s3key
    secret_key = var.s3secret

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

provider "yandex" {
  service_account_key_file = var.sauth
  cloud_id = var.cloud
  folder_id = var.folder
}

