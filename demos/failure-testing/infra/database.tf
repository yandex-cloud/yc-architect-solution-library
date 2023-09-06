module "db" {
  #source = "git::https://github.com/terraform-yc-modules/terraform-yc-postgresql"
  source = "../modules/terraform-yc-postgresql"

  network_id               = local.network_id
  folder_id                = local.folder_id
  name                     = "todoapp${local.name_suffix}"
  description              = "todoapp database"
  resource_preset_id       = "s3-c2-m8"
  security_groups_ids_list = [yandex_vpc_security_group.db.id]

  maintenance_window = {
    type = "WEEKLY"
    day  = "SUN"
    hour = "02"
  }

  access_policy = {
    web_sql = true
  }

  performance_diagnostics = {
    enabled = true
  }

  hosts_definition = [for zone in var.zones : {
    zone             = module.network.subnets["db-${zone}"].zone
    subnet_id        = module.network.subnets["db-${zone}"].id
    assign_public_ip = false
    }
  ]

  postgresql_config = {
    max_connections                = 395
    enable_parallel_hash           = true
    autovacuum_vacuum_scale_factor = 0.34
    default_transaction_isolation  = "TRANSACTION_ISOLATION_READ_COMMITTED"
    shared_preload_libraries       = "SHARED_PRELOAD_LIBRARIES_AUTO_EXPLAIN,SHARED_PRELOAD_LIBRARIES_PG_HINT_PLAN"
  }

  default_user_settings = {
    default_transaction_isolation = "read committed"
    log_min_duration_statement    = 5000
  }

  databases = [
    {
      name       = var.todoapp_db
      owner      = var.todoapp_owner
      lc_collate = "ru_RU.UTF-8"
      lc_type    = "ru_RU.UTF-8"
      extensions = ["uuid-ossp"]
    }
  ]

  owners = [
    {
      name       = var.todoapp_owner
      conn_limit = 200
    }
  ]
}

resource "yandex_vpc_security_group" "db" {
  name        = "db${local.name_suffix}"
  description = "database security group"
  network_id  = local.network_id
  folder_id   = local.folder_id

  ingress {
    protocol       = "ICMP"
    description    = "ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "database host"
    v4_cidr_blocks = flatten([for subnet in module.network.subnets : subnet.v4_cidr_blocks])
    port           = 6432
  }

  ingress {
    protocol          = "TCP"
    description       = "Rule allows availability checks from load balancer's address range. It is required for a db cluster"
    predefined_target = "loadbalancer_healthchecks"
    from_port         = 0
    to_port           = 65535
  }

  ingress {
    protocol          = "ANY"
    description       = "Rule allows master and slave communication inside a security group."
    predefined_target = "self_security_group"
    from_port         = 0
    to_port           = 65535
  }
}
