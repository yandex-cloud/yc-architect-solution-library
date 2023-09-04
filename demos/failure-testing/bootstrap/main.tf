data "yandex_client_config" "client" {}

resource "random_string" "uniq" {
  count   = var.uniq_names == true ? 1 : 0
  length  = 8
  upper   = false
  lower   = true
  numeric = true
  special = false
}

locals {
  cloud_id           = var.cloud_id == null ? data.yandex_client_config.client.cloud_id : var.cloud_id
  folder_id_existing = var.folder_id == null ? data.yandex_client_config.client.folder_id : var.folder_id
  folder_id          = var.folder_create == true ? yandex_resourcemanager_folder.folder.0.id : local.folder_id_existing
  network_id         = var.network_id == null ? yandex_vpc_network.this.0.id : var.network_id
  dns_zone_id        = var.dns_zone_id == null ? yandex_dns_zone.dns_zone.0.id : var.dns_zone_id
  dns_domain_ts      = var.dns_zone_id == null ? trimsuffix(var.dns_domain, ".") : trimsuffix(data.yandex_dns_zone.dns_zone.zone, ".")
  ip_addr            = var.ip_addr == null ? yandex_vpc_address.addr.0.external_ipv4_address.0.address : var.ip_addr
  fqdns              = [for hostname in var.dns_hostnames : "${hostname}.${local.dns_domain_ts}"]
  fqdn               = element(local.fqdns, 0)
  cr_id              = var.cr_id == null ? yandex_container_registry.cr.0.id : var.cr_id
  name_suffix        = var.uniq_names == true ? "-${random_string.uniq.0.result}" : ""
  cr                 = "cr.yandex/${local.cr_id}"
}

resource "yandex_resourcemanager_folder" "folder" {
  count       = var.folder_create == true ? 1 : 0
  cloud_id    = local.cloud_id
  name        = "${var.folder_name}${local.name_suffix}"
  description = var.folder_description
}

resource "yandex_iam_service_account" "ft_owner" {
  count       = var.ft_sa_id == null ? 1 : 0
  name        = "${var.ft_sa_name}${local.name_suffix}"
  description = var.ft_sa_description
  folder_id   = local.folder_id
}

resource "yandex_iam_service_account_key" "ft_owner" {
  count              = var.ft_sa_id == null ? 1 : 0
  service_account_id = yandex_iam_service_account.ft_owner.0.id
  description        = "key for ${var.ft_sa_description}"
  key_algorithm      = "RSA_2048"
}

resource "yandex_resourcemanager_folder_iam_member" "ft_owner_roles" {
  for_each  = toset(var.ft_sa_id == null ? ["admin"] : [])
  folder_id = local.folder_id

  role   = each.key
  member = "serviceAccount:${yandex_iam_service_account.ft_owner.0.id}"
}

resource "yandex_vpc_address" "addr" {
  count     = var.ip_addr == null ? 1 : 0
  name      = "${var.ip_addr_name}${local.name_suffix}"
  folder_id = local.folder_id

  external_ipv4_address {
    zone_id = var.ip_addr_zone
  }
}

resource "yandex_vpc_network" "this" {
  count       = var.network_id == null ? 1 : 0
  name        = var.network_name
  description = var.network_description
  folder_id   = local.folder_id
}

data "yandex_dns_zone" "dns_zone" {
  dns_zone_id = local.dns_zone_id
  folder_id   = local.folder_id
}

resource "yandex_dns_zone" "dns_zone" {
  count       = var.dns_zone_id == null ? 1 : 0
  name        = replace(trimsuffix(var.dns_domain, "."), ".", "-")
  description = "Failure testing zone"
  folder_id   = local.folder_id
  zone        = "${trimsuffix(var.dns_domain, ".")}."
  public      = true
}

resource "yandex_dns_recordset" "dns_rec_a" {
  for_each = toset(var.dns_hostnames)
  zone_id  = local.dns_zone_id
  name     = each.key
  type     = "A"
  ttl      = 600
  data     = [local.ip_addr]
}

resource "yandex_dns_recordset" "dns_rec_a_wildcard" {
  count   = var.dns_wildcard_enable == true ? 1 : 0
  zone_id = local.dns_zone_id
  name    = "*"
  type    = "A"
  ttl     = 600
  data    = [local.ip_addr]
}

resource "yandex_cm_certificate" "le_cert" {
  name      = replace(local.dns_domain_ts, ".", "-")
  domains   = [local.dns_domain_ts, "*.${local.dns_domain_ts}"]
  folder_id = local.folder_id
  managed {
    challenge_type = "DNS_CNAME"
  }
}

resource "yandex_dns_recordset" "validation_dns_rec" {
  zone_id = local.dns_zone_id
  name    = yandex_cm_certificate.le_cert.challenges[0].dns_name
  type    = yandex_cm_certificate.le_cert.challenges[0].dns_type
  data    = [yandex_cm_certificate.le_cert.challenges[0].dns_value]
  ttl     = 600
}

resource "yandex_container_registry" "cr" {
  count     = var.cr_id == null ? 1 : 0
  name      = "${var.cr_name}${local.name_suffix}"
  folder_id = var.cr_folder_id == null ? local.folder_id : var.cr_folder_id
}

resource "yandex_iam_service_account" "cr_pusher" {
  count       = var.cr_id == null ? 1 : 0
  name        = var.cr_sa_name == null ? "${var.cr_name}-registry-pusher${local.name_suffix}" : "${var.cr_sa_name}${local.name_suffix}"
  description = var.cr_sa_description
  folder_id   = var.cr_folder_id == null ? local.folder_id : var.cr_folder_id
}

resource "yandex_container_registry_iam_binding" "cr_pusher" {
  count       = var.cr_id == null ? 1 : 0
  registry_id = yandex_container_registry.cr.0.id
  role        = "container-registry.images.pusher"

  members = [
    "serviceAccount:${yandex_iam_service_account.cr_pusher.0.id}",
  ]
}

resource "yandex_iam_service_account_key" "cr_pusher" {
  count              = var.cr_id == null ? 1 : 0
  service_account_id = yandex_iam_service_account.cr_pusher.0.id
  description        = "key for ${var.cr_sa_description}"
  key_algorithm      = "RSA_2048"
}

resource "local_file" "cr_pusher_key" {
  count                = var.cr_id == null && var.cr_sa_key_filename != null ? 1 : 0
  filename             = pathexpand(var.cr_sa_key_filename)
  directory_permission = "0750"
  file_permission      = "0600"
  content = jsonencode(
    {
      "id" : yandex_iam_service_account_key.cr_pusher.0.id,
      "service_account_id" : yandex_iam_service_account_key.cr_pusher.0.service_account_id,
      "created_at" : yandex_iam_service_account_key.cr_pusher.0.created_at,
      "key_algorithm" : yandex_iam_service_account_key.cr_pusher.0.key_algorithm,
      "public_key" : yandex_iam_service_account_key.cr_pusher.0.public_key,
      "private_key" : yandex_iam_service_account_key.cr_pusher.0.private_key
    }
  )
}

output "fqdns" {
  value = local.fqdns
}

output "folder_id" {
  value = local.folder_id
}

output "network_id" {
  value = local.network_id
}

output "dns_zone_id" {
  value = local.dns_zone_id
}

output "ip_addr" {
  value = local.ip_addr
}

output "cert_id" {
  value = yandex_cm_certificate.le_cert.id
}

output "cr_id" {
  value = local.cr_id
}

output "name_suffix" {
  value = random_string.uniq.0.result
}
