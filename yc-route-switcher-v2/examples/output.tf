output "nat-a_public_ip_address" {
  value = yandex_vpc_address.public_ip_nat_a.external_ipv4_address.0.address
}

output "nat-b_public_ip_address" {
  value = yandex_vpc_address.public_ip_nat_b.external_ipv4_address.0.address
}

output "path_for_private_ssh_key" {
  value = "./pt_key.pem"
}

output "vm_username" {
  value = var.vm_username
}

output "test_vm_password" {
  value = random_string.test_vm_password.result
  sensitive = true
}