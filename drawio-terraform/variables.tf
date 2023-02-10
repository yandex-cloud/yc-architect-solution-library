# ===============
# Deployment data
# ===============

variable "cloud_id" {
  description = "take value from the environment variable"
}

variable "folder_id" {
  description = "take value from the environment variable"
}

variable "net_name" {
  default = "default"
}

variable "zone" {
  default = "ru-central1-a"
}

variable "image_family" {
  default = "ubuntu-2204-lts"
}

variable "vm_name" {
  default = "test-vm"
}

variable "draw_template_name" {
  default = "vm-drawio.tpl"
}

variable "draw_name" {
  default = "test-vm.drawio"
}


# ============
# Data Sources
# ============

data "yandex_vpc_subnet" "subnet" {
  folder_id = var.folder_id
  name = "${var.net_name}-${var.zone}"
}

data "yandex_compute_image" "image" {
  family = var.image_family
}
