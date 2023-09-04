output "cluster_id" {
  description = "PostgreSQL cluster ID"
  value       = yandex_mdb_postgresql_cluster.this.id
}

output "cluster_name" {
  description = "PostgreSQL cluster name"
  value       = yandex_mdb_postgresql_cluster.this.name
}

output "cluster_host_names_list" {
  description = "PostgreSQL cluster host name"
  value       = [yandex_mdb_postgresql_cluster.this.host[*].name]
}

output "cluster_fqdns_list" {
  description = "PostgreSQL cluster nodes FQDN list"
  value       = [yandex_mdb_postgresql_cluster.this.host[*].fqdn]
}

output "owners_data" {
  description = "List of owners with passwords."
  sensitive   = true
  value = [
    for u in yandex_mdb_postgresql_user.owner : {
      user     = u.name
      password = u.password
    }
  ]
}

output "users_data" {
  description = "List of users with passwords."
  sensitive   = true
  value = [
    for u in yandex_mdb_postgresql_user.user : {
      user     = u.name
      password = u.password
    }
  ]
}

output "databases" {
  description = "List of databases names."
  value       = [for db in var.databases : db.name]
}

output "connection_step_1" {
  description = "1 step - Install certificate"
  value       = "mkdir --parents ~/.postgresql && curl -sfL 'https://storage.yandexcloud.net/cloud-certs/CA.pem' -o ~/.postgresql/root.crt && chmod 0600 ~/.postgresql/root.crt"
}

output "connection_step_2" {
  description = <<EOF
    How connect to PostgreSQL cluster?

    1. Install certificate
    
      mkdir --parents \~/.postgresql && \\
      curl -sfL "https://storage.yandexcloud.net/cloud-certs/CA.pem" -o \~/.postgresql/root.crt && \\
      chmod 0600 \~/.postgresql/root.crt
    
    2. Run connection string from the output value, for example
    
      psql "host=rc1a-g2em5m3zc9dxxasn.mdb.yandexcloud.net \\
        port=6432 \\
        sslmode=verify-full \\
        dbname=db-b \\
        user=owner-b \\
        target_session_attrs=read-write"
    
  EOF
  value       = "psql 'host=c-${yandex_mdb_postgresql_cluster.this.id}.rw.mdb.yandexcloud.net port=6432 sslmode=verify-full dbname=${var.databases[0]["name"]} user=${var.databases[0]["owner"]} target_session_attrs=read-write'"
}
