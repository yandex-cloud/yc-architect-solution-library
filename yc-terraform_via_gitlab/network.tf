resource "yandex_vpc_network" "testing" {
  name = "testing"
}

resource "yandex_vpc_subnet" "test_sub" {
  name = "test_sub"
  v4_cidr_blocks = ["10.100.100.0/24", "192.168.100.0/24"]
  zone = var.zones["A"]
  network_id = yandex_vpc_network.testing.id
}

