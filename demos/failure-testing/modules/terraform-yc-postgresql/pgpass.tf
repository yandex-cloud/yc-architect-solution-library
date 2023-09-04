resource "local_file" "pgpass_file" {
  count           = var.pgpass_path == null ? 0 : 1
  content         = <<-EOT
%{for db in yandex_mdb_postgresql_database.database~}
c-${yandex_mdb_postgresql_cluster.this.id}.rw.mdb.yandexcloud.net:6432:${db.name}:${db.owner}:${yandex_mdb_postgresql_user.owner[db.owner].password}
%{endfor~}
  EOT
  filename        = pathexpand(var.pgpass_path)
  file_permission = "0600"
}
