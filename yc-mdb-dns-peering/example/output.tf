
output "dns_vm_ip" {
  value = yandex_compute_instance.dns_srv.network_interface.0.nat_ip_address
}



output "bu_1_db_hosts" {
  value = yandex_mdb_mysql_cluster.bu_1_db.host.*.fqdn
}


output "bu_1_db_cname" {
  value = "c-${yandex_mdb_mysql_cluster.bu_1_db.id}.rw.mdb.yandexcloud.net"
}


output "bu_2_db_hosts" {
  value = yandex_mdb_mysql_cluster.bu_2_db.host.*.fqdn
}


output "bu_2_db_cname" {
  value = "c-${yandex_mdb_mysql_cluster.bu_2_db.id}.rw.mdb.yandexcloud.net"
}