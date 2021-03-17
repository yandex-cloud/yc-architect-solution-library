
variable "yc_image_family" {
  default = "ubuntu-2004-lts"
}


variable "public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "zones" {
  description = "Yandex Cloud default Zone for provisoned resources"
  default = ["ru-central1-a","ru-central1-b","ru-central1-c"]
}

variable "cluster_size" {
  default = 3
}
