output "docker-machine" {
  description = "ssh command for connection"
  value       = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${var.username}@${yandex_compute_instance.gitlab_docker_machine.network_interface[0].nat_ip_address}"
}
