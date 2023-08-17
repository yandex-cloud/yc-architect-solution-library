output "path_for_private_ssh_key" {
  value = "./pt_key.pem"
}

output "vm_username" {
  value = var.vm_username
}

output "test_vm_password" {
  value = random_password.test_vm_password.result
  sensitive = true
}

output "s3_nlb_ip_address" {
  value = tolist(tolist(yandex_lb_network_load_balancer.s3_nlb.listener)[0].internal_address_spec)[0].address
}

output "s3_bucket_name" {
  value = yandex_storage_bucket.s3_test_bucket.bucket
}

output "s3_test_command" {
  value = "aws --endpoint-url=https://${var.s3_fqdn} s3 cp s3://${yandex_storage_bucket.s3_test_bucket.bucket}/${yandex_storage_object.s3_test_file.key} ${yandex_storage_object.s3_test_file.key}"
}

