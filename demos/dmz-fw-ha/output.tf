output "path_for_private_ssh_key" {
  value = "./pt_key.pem"
}

output "fw_mgmt-server_ip_address" {
  value = yandex_compute_instance.mgmt-server.network_interface.0.ip_address
}

output "fw-a_ip_address" {
  value = yandex_compute_instance.fw-a.network_interface.0.ip_address
}

output "fw-b_ip_address_fw-b" {
  value = yandex_compute_instance.fw-b.network_interface.0.ip_address
}

output "fw_gaia_portal_mgmt-server_password" {
  value = "admin"
}

output "fw_smartconsole_mgmt-server_password" {
  value = "${random_password.pass-sms[0].result}"
  sensitive = true
}

output "fw_sic-password" {
  value = "${random_password.pass-sic[0].result}"
  sensitive = true
}

output "jump-vm_public_ip_address_jump-vm" {
  value = yandex_vpc_address.public-ip-jump-vm.external_ipv4_address.0.address
}

output "jump-vm_path_for_WireGuard_client_config" {
  value = "./jump-vm-wg.conf"
}

output "fw-alb_public_ip_address" {
  value = yandex_vpc_address.public-ip-fw-alb.external_ipv4_address.0.address
}

output "dmz-web-server-nlb_ip_address" {
  value = "${cidrhost(var.subnet-a_vpc_1, 100)}"
}

output "route-switcher_nlb" {
  value = module.route_switcher.nlb_for_route-switcher
}

output "route-switcher_bucket" {
  value = module.route_switcher.bucket_for_route-switcher
}

output "route-switcher_function" {
  value = module.route_switcher.route-switcher_function
}