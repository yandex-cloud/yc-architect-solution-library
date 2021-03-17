resource "yandex_vpc_network" "infra_net" {
  name = "infra-net1"
}


resource "yandex_vpc_subnet" "infra_subnet" {
  count          = "${var.cluster_size > length(var.zones) ? length(var.zones)  : var.cluster_size}"
  name           = "infra-subnet1-${count.index}"
  zone           = element(var.zones,count.index)
  network_id     = yandex_vpc_network.infra_net.id
  v4_cidr_blocks = ["10.1.${count.index}.0/24"]
}

resource "yandex_vpc_network" "bu_1_net" {
  name = "bu-1-net1"
}


resource "yandex_vpc_subnet" "bu_1_subnet" {
  count          = "${var.cluster_size > length(var.zones) ? length(var.zones)  : var.cluster_size}"
  name           = "bu-1-subnet1-${count.index}"
  zone           = element(var.zones,count.index)
  network_id     = yandex_vpc_network.bu_1_net.id
  v4_cidr_blocks = ["10.200.${count.index}.0/24"]
}

resource "yandex_vpc_network" "bu_2_net" {
  name = "bu-2-net1"
}


resource "yandex_vpc_subnet" "bu_2_subnet" {
  count          = "${var.cluster_size > length(var.zones) ? length(var.zones)  : var.cluster_size}"
  name           = "bu-2-subnet1-${count.index}"
  zone           = element(var.zones,count.index)
  network_id     = yandex_vpc_network.bu_2_net.id
  v4_cidr_blocks = ["10.201.${count.index}.0/24"]
}
