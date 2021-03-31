output "network_a_vm_external_ip_address" {
  value = yandex_compute_instance.network_a_user_vm.0.network_interface.0.nat_ip_address
}

output "network_b_vm_internal_ip_address" {
  value = yandex_compute_instance.network_b_user_vm.network_interface.0.ip_address
}


output "vpn_vm_id" {
  value = yandex_compute_instance.network_a_vpn_vm.0.id
}