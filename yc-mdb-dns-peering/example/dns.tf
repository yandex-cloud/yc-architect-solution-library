resource "yandex_dns_zone" "zone1" {
  name        = "mdb-zone"
  description = "desc"



  zone             = "mdb.yandexcloud.net."
  public           = false
  private_networks = [yandex_vpc_network.infra_net.id,yandex_vpc_network.bu_1_net.id,yandex_vpc_network.bu_2_net.id]
}


