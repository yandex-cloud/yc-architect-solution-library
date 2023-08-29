// create vpc if not specified
resource "yandex_vpc_network" "vpc" {
  count = var.vpc_id == null ? 1 : 0
  name  = "s3-vpc"
  folder_id = var.folder_id
}

// create subnets for NAT instances
resource "yandex_vpc_subnet" "nat_vm_subnets" {
  count = length(var.yc_availability_zones)
  name           = "s3-subnet-${substr(var.yc_availability_zones[count.index], -1, -1)}"
  folder_id      = var.folder_id
  zone           = var.yc_availability_zones[count.index]
  network_id     = var.vpc_id == null ? yandex_vpc_network.vpc[0].id : var.vpc_id
  v4_cidr_blocks = [var.subnet_prefix_list[count.index]]
}

// create subnet for test-vm
resource "yandex_vpc_subnet" "test_subnet" {
  name           = "test-s3-subnet-a"
  folder_id      = var.folder_id
  zone           = var.yc_availability_zones[0]
  network_id     = var.vpc_id == null ? yandex_vpc_network.vpc[0].id : var.vpc_id
  v4_cidr_blocks = ["10.10.10.0/24"]
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
  name    = "${yandex_storage_bucket.s3_bucket.bucket}"
  type    = "A"
  ttl     = 300
  data    = ["${tolist(tolist(yandex_lb_network_load_balancer.s3_nlb.listener)[0].internal_address_spec)[0].address}"]  
}

// List of static public IPs for NAT-instances 
resource "yandex_vpc_address" "public_ip_list" {
  count = var.nat_instances_count
  name = "pub-ip-${substr(var.yc_availability_zones[count.index % length(var.yc_availability_zones)], -1, -1)}${count.index + 1}"
  folder_id = var.folder_id
  external_ipv4_address {
    zone_id = var.yc_availability_zones[count.index % length(var.yc_availability_zones)]
  }
}
