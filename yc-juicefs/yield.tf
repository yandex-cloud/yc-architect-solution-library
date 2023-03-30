output "redis" {
  value = "redis://:<pwd>@${yandex_mdb_redis_cluster.juicefs-redis.host[0].fqdn}:6379/1"
}

output "connect_line" {
  value = "ssh juicefs@${yandex_compute_instance.client_node_a[0].network_interface[0].nat_ip_address}"
}


