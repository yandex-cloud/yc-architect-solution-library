data "yandex_client_config" "client" {}

locals {
  folder_id = var.folder_id == null ? data.yandex_client_config.client.folder_id : var.folder_id
}

# PostgreSQL cluster
resource "yandex_mdb_postgresql_cluster" "this" {
  name                = var.name
  description         = var.description
  environment         = var.environment
  network_id          = var.network_id
  folder_id           = local.folder_id
  labels              = var.labels
  host_master_name    = var.host_master_name
  deletion_protection = var.deletion_protection
  security_group_ids  = var.security_groups_ids_list

  config {
    version                   = var.pg_version
    postgresql_config         = var.postgresql_config
    autofailover              = var.autofailover
    backup_retain_period_days = var.backup_retain_period_days

    resources {
      disk_size          = var.disk_size
      disk_type_id       = var.disk_type
      resource_preset_id = var.resource_preset_id
    }

    dynamic "access" {
      for_each = range(var.access_policy == null ? 0 : 1)
      content {
        data_lens     = var.access_policy.data_lens
        web_sql       = var.access_policy.web_sql
        serverless    = var.access_policy.serverless
        data_transfer = var.access_policy.data_transfer
      }
    }

    dynamic "performance_diagnostics" {
      for_each = range(var.performance_diagnostics == null ? 0 : 1)
      content {
        enabled                      = var.performance_diagnostics.enabled
        sessions_sampling_interval   = var.performance_diagnostics.sessions_sampling_interval
        statements_sampling_interval = var.performance_diagnostics.statements_sampling_interval
      }
    }

    dynamic "backup_window_start" {
      for_each = range(var.backup_window_start == null ? 0 : 1)
      content {
        hours   = var.backup_window_start.hours
        minutes = var.backup_window_start.minutes
      }
    }

    dynamic "pooler_config" {
      for_each = range(var.pooler_config == null ? 0 : 1)
      content {
        pool_discard = var.pooler_config.pool_discard
        pooling_mode = var.pooler_config.pooling_mode
      }
    }
  }

  dynamic "host" {
    for_each = var.hosts_definition
    content {
      name                    = host.value.name
      zone                    = host.value.zone
      subnet_id               = host.value.subnet_id
      assign_public_ip        = host.value.assign_public_ip
      priority                = host.value.priority
      replication_source_name = host.value.replication_source_name
    }
  }

  dynamic "restore" {
    for_each = range(var.restore_parameters == null ? 0 : 1)
    content {
      backup_id      = var.restore_parameters.backup_id
      time           = var.restore_parameters.time
      time_inclusive = var.restore_parameters.time_inclusive
    }
  }

  dynamic "maintenance_window" {
    for_each = range(var.maintenance_window == null ? 0 : 1)
    content {
      type = var.maintenance_window.type
      day  = var.maintenance_window.day
      hour = var.maintenance_window.hour
    }
  }

}
