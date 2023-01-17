resource "yandex_mdb_postgresql_cluster" "pg_cluster_1" {
  name        = "pg-cluster-1"
  environment = "PRESTABLE"
  network_id  = local.vpc_id
  security_group_ids = local.sg_id
  folder_id = local.folder_id
  config {
    version = 14
    resources {
      resource_preset_id = "s2.micro"
      disk_type_id       = "network-ssd"
      disk_size          = 32
    }
    postgresql_config = {
      max_connections                   = 400
      enable_parallel_hash              = true
      default_transaction_isolation     = "TRANSACTION_ISOLATION_READ_COMMITTED"
      shared_preload_libraries          = "SHARED_PRELOAD_LIBRARIES_AUTO_EXPLAIN,SHARED_PRELOAD_LIBRARIES_PG_HINT_PLAN"
    }
  }

  maintenance_window {
    type = "WEEKLY"
    day  = "SAT"
    hour = 1
  }

  host {
    zone  = var.default_zone
    subnet_id = local.subnet_id
    assign_public_ip = true
    name = "db-master"
  }
}

resource "yandex_mdb_postgresql_user" "user_owner" {
  cluster_id = yandex_mdb_postgresql_cluster.pg_cluster_1.id
  name       = "user_owner"
  password   = var.user_owner_passwd
}

resource "yandex_mdb_postgresql_user" "user_ro" {
  cluster_id = yandex_mdb_postgresql_cluster.pg_cluster_1.id
  name       = "user_ro"
  password   = var.user_ro_passwd
  conn_limit = 20
  settings = {
    default_transaction_isolation = "read committed"
    log_min_duration_statement    = 5000
  }
  permission {
    database_name = yandex_mdb_postgresql_database.db1.name
  }
}

resource "yandex_mdb_postgresql_database" "db1" {
  cluster_id = yandex_mdb_postgresql_cluster.pg_cluster_1.id
  name       = "db1"
  owner      = yandex_mdb_postgresql_user.user_owner.name
  lc_collate = "en_US.UTF-8"
  lc_type    = "en_US.UTF-8"
  extension {
    name = "uuid-ossp"
  }
  extension {
    name = "xml2"
  }
}

provider "postgresql" {
  host            = yandex_mdb_postgresql_cluster.pg_cluster_1.host[0].fqdn
  port            = 6432
  database        = yandex_mdb_postgresql_database.db1.name
  username        = yandex_mdb_postgresql_user.user_owner.name
  password        = yandex_mdb_postgresql_user.user_owner.password
  sslmode         = "require"
  connect_timeout = 15
#  clientcert {
#    cert = "/path/to/public-certificate.pem"
#    key  = "/path/to/private-key.pem"
#  }
}

resource "null_resource" "restore_database" {
  depends_on = [ yandex_mdb_postgresql_database.db1, yandex_mdb_postgresql_user.user_owner ]
  provisioner "local-exec" {
    command = "psql -f db1.pg_dump"
    environment = {
      PGHOST = yandex_mdb_postgresql_cluster.pg_cluster_1.host[0].fqdn
      PGPORT = 6432
      PGDATABASE = yandex_mdb_postgresql_database.db1.name
      PGUSER = yandex_mdb_postgresql_user.user_owner.name
      PGPASSWORD = yandex_mdb_postgresql_user.user_owner.password
    }
  }
}

resource "postgresql_grant" "readonly_tables" {
  database    = yandex_mdb_postgresql_database.db1.name
  role        = yandex_mdb_postgresql_user.user_ro.name
  schema      = "public"
  object_type = "table"
#  objects     = ["table1"]
  privileges  = ["SELECT"]
  with_grant_option = "false"
  depends_on = [ null_resource.restore_database ]
}

