// create vpc if not specified
resource "yandex_vpc_network" "vpc" {
  count = var.vpc_id == null ? 1 : 0
  name  = "s3-vpc"
  folder_id = var.folder_id
}

// create subnets for NAT instances if not specified
resource "yandex_vpc_subnet" "nat_instances_subnets" {
  count = length(var.subnet_id_list) == 0 ? length(var.yc_availability_zones) : 0

  name           = "s3-subnet-${substr(element(var.yc_availability_zones, count.index), -1, -1)}"
  folder_id      = var.folder_id
  zone           = element(var.yc_availability_zones, count.index)
  network_id     = var.vpc_id == null ? yandex_vpc_network.vpc[0].id : var.vpc_id
  v4_cidr_blocks = ["10.10.${count.index + 1}.0/24"]
}

// create subnet for test-vm
resource "yandex_vpc_subnet" "test_subnet" {
  name           = "test-s3-subnet-a"
  folder_id      = var.folder_id
  zone           = element(var.yc_availability_zones, 0)
  network_id     = var.vpc_id == null ? yandex_vpc_network.vpc[0].id : var.vpc_id
  v4_cidr_blocks = ["10.10.10.0/24"]
}

// get datasource for first subnet from var.subnet_id_list
data "yandex_vpc_subnet" "first_subnet" {
  count          = length(var.subnet_id_list) == 0 ? 0 : 1
  subnet_id      = var.subnet_id_list[0]
}

// create internal DNS zone for Object Storage Endpoint
resource "yandex_dns_zone" "s3_zone" {
  folder_id = var.folder_id
  name        = "s3-zone"
  description = "Internal zone for S3 Endpoint"
  zone             = "${var.s3_fqdn}."
  public           = false
  private_networks = [var.vpc_id == null ? yandex_vpc_network.vpc[0].id : var.vpc_id]
}

// create DNS 'A' record for Object Storage Endpoint mapped to IP address of internal NLB
resource "yandex_dns_recordset" "s3-endpoint-dns-rec" {
  zone_id = yandex_dns_zone.s3_zone.id
  name    = "@"
  type    = "A"
  ttl     = 300
  data    = ["${tolist(tolist(yandex_lb_network_load_balancer.s3_nlb.listener)[0].internal_address_spec)[0].address}"]  
}

resource "yandex_dns_recordset" "s3-endpoint-bucket-dns-rec" {
  zone_id = yandex_dns_zone.s3_zone.id
  name    = "${yandex_storage_bucket.s3_test_bucket.bucket}"
  type    = "A"
  ttl     = 300
  data    = ["${tolist(tolist(yandex_lb_network_load_balancer.s3_nlb.listener)[0].internal_address_spec)[0].address}"]  
}



