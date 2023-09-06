resource "random_password" "password" {
  for_each         = { for v in concat(var.owners, var.users) : v.name => v if v.password == null }
  length           = 16
  special          = true
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  override_special = "-_()[]{}!%^"
}

# PostgreSQL databases owners
resource "yandex_mdb_postgresql_user" "owner" {
  for_each = length(var.owners) > 0 ? { for owner in var.owners : owner.name => owner } : {}

  cluster_id          = yandex_mdb_postgresql_cluster.this.id
  name                = each.value.name
  password            = each.value.password == null ? random_password.password[each.value.name].result : each.value.password
  grants              = each.value.grants
  login               = each.value.login
  conn_limit          = each.value.conn_limit
  deletion_protection = each.value.deletion_protection
  settings            = merge(var.default_user_settings, each.value.settings)
}

# PostgreSQL users with own permissions
resource "yandex_mdb_postgresql_user" "user" {
  for_each = length(var.users) > 0 ? { for user in var.users : user.name => user } : {}

  cluster_id          = yandex_mdb_postgresql_cluster.this.id
  name                = each.value.name
  password            = each.value.password == null ? random_password.password[each.value.name].result : each.value.password
  grants              = each.value.grants
  login               = each.value.login
  conn_limit          = each.value.conn_limit
  deletion_protection = each.value.deletion_protection
  settings            = merge(var.default_user_settings, each.value.settings)

  dynamic "permission" {
    for_each = each.value.permissions
    content {
      database_name = yandex_mdb_postgresql_database.database[permission.value].name
    }
  }
}
