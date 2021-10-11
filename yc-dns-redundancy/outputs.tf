# ========
# Outputs
# ========

output "dns_set" {
  value = local.dns_set
}

output "vm_ext_ip_address" {
  value = yandex_compute_instance.vm_instance.network_interface[0].nat_ip_address
}

output "vm_int_ip_address" {
  value = yandex_compute_instance.vm_instance.network_interface[0].ip_address
}

output "vm_id" {
  value = yandex_compute_instance.vm_instance.id
}
