
output "db_host" {
  value = "${yandex_mdb_postgresql_cluster.pg_cluster_1.host[0].fqdn}"
}
