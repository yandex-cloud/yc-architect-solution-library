# Variables
variable "name" {
  description = "PostgreSQL cluster name"
  type        = string
  default     = "pgsql-cluster"
}

variable "environment" {
  description = "Environment type: PRODUCTION or PRESTABLE"
  type        = string
  default     = "PRODUCTION"
  validation {
    condition     = contains(["PRODUCTION", "PRESTABLE"], var.environment)
    error_message = "Release channel should be PRODUCTION (stable feature set) or PRESTABLE (early bird feature access)."
  }
}

variable "network_id" {
  description = "Network id of the PostgreSQL cluster"
  type        = string
}

variable "description" {
  description = "PostgreSQL cluster description"
  type        = string
  default     = "Managed PostgreSQL cluster"
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID where the cluster resides"
  type        = string
  default     = null
}

variable "labels" {
  description = "Set of label pairs to assing to the PostgreSQL cluster"
  type        = map(any)
  default     = {}
}

variable "host_master_name" {
  description = "Name of the master host."
  type        = string
  default     = null
}

variable "security_groups_ids_list" {
  description = "List of security group IDs to which the PostgreSQL cluster belongs"
  type        = list(string)
  default     = []
  nullable    = true
}

variable "deletion_protection" {
  description = "Protects the cluster from deletion"
  type        = bool
  default     = false
}

variable "pg_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15"
  validation {
    condition     = contains(["11", "11-1c", "12", "12-1c", "13", "13-1c", "14", "14-1c", "15"], var.pg_version)
    error_message = "Allowed PostgreSQL versions are 11, 11-1c, 12, 12-1c, 13, 13-1c, 14, 14-1c, 15."
  }
}

variable "disk_size" {
  description = "Disk size for every cluster host"
  type        = number
  default     = 20
}

variable "disk_type" {
  description = "Disk type for all cluster hosts"
  type        = string
  default     = "network-ssd"
}

variable "resource_preset_id" {
  description = "Preset for hosts"
  type        = string
  default     = "s2.micro"
}

variable "access_policy" {
  description = "Access policy from other services to the PostgreSQL cluster."
  type = object({
    data_lens     = optional(bool, null)
    web_sql       = optional(bool, null)
    serverless    = optional(bool, null)
    data_transfer = optional(bool, null)
  })
  default = {}
}

variable "restore_parameters" {
  description = <<EOF
    The cluster will be created from the specified backup.
    NOTES:
      - backup_id must be specified to create a new PostgreSQL cluster from a backup.
      - time format is 'yyy-mm-ddThh:mi:ss', where T is a delimeter, e.g. "2023-04-05T11:22:33".
      - time_inclusive indicates recovery to nearest recovery point just before (false) or right after (true) the time.
  EOF
  type = object({
    backup_id      = string
    time           = optional(string, null)
    time_inclusive = optional(bool, null)
  })
  default = null
}

variable "maintenance_window" {
  description = <<EOF
    (Optional) Maintenance policy of the PostgreSQL cluster.
      - type - (Required) Type of maintenance window. Can be either ANYTIME or WEEKLY. A day and hour of window need to be specified with weekly window.
      - day  - (Optional) Day of the week (in DDD format). Allowed values: "MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"
      - hour - (Optional) Hour of the day in UTC (in HH format). Allowed value is between 0 and 23.
  EOF
  type = object({
    type = string
    day  = optional(string, null)
    hour = optional(string, null)
  })
  default = {
    type = "ANYTIME"
  }
}

variable "performance_diagnostics" {
  description = "(Optional) PostgreSQL cluster performance diagnostics settings."
  type = object({
    enabled                      = optional(bool, null)
    sessions_sampling_interval   = optional(number, 60)
    statements_sampling_interval = optional(number, 600)
  })
  default = {}
}

variable "backup_retain_period_days" {
  description = "(Optional) The period in days during which backups are stored."
  type        = number
  default     = null
}

variable "backup_window_start" {
  description = "(Optional) Time to start the daily backup, in the UTC timezone."
  type = object({
    hours   = string
    minutes = optional(string, "00")
  })
  default = null
}

variable "autofailover" {
  description = "(Optional) Configuration setting which enables and disables auto failover in the cluster."
  type        = bool
  default     = true
}

variable "pooler_config" {
  description = <<EOF
    Configuration of the connection pooler.
      - pool_discard - Setting pool_discard parameter in Odyssey. Values: yes | no
      - pooling_mode - Mode that the connection pooler is working in. Values: `POOLING_MODE_UNSPECIFIED`, `SESSION`, `TRANSACTION`, `STATEMENT`
  EOF
  type = object({
    pool_discard = optional(bool, null)
    pooling_mode = optional(string, null)
  })
  default = null
}

variable "hosts_definition" {
  description = "List of PostgreSQL hosts."

  type = list(object({
    name                    = optional(string, null)
    zone                    = string
    subnet_id               = optional(string, null)
    assign_public_ip        = optional(bool, false)
    replication_source_name = optional(string, null)
    priority                = optional(number, null)
  }))
  default = []
}

variable "postgresql_config" {
  description = <<EOF
    Map of PostgreSQL cluster configuration.
    Details info in a 'PostgreSQL cluster settings' of official documentation.
    Link: https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/mdb_postgresql_cluster#postgresql-cluster-settings
  EOF
  type        = map(any)
  default     = null
}

variable "databases" {
  description = <<EOF
    List of PostgreSQL databases.

    Required values:
      - name                - (Required) The name of the database.
      - owner               - (Required) Name of the user assigned as the owner of the database. Forbidden to change in an existing database.
      - extension           - (Optional) Set of database extensions. 
      - lc_collate          - (Optional) POSIX locale for string sorting order. Forbidden to change in an existing database.
      - lc_type             - (Optional) POSIX locale for character classification. Forbidden to change in an existing database.
      - template_db         - (Optional) Name of the template database.
      - deletion_protection - (Optional) A deletion protection.
  EOF
  type = list(object({
    name                = string
    owner               = string
    lc_collate          = optional(string, null)
    lc_type             = optional(string, null)
    template_db         = optional(string, null)
    deletion_protection = optional(bool, null)
    extensions          = optional(list(string), [])
  }))
}

variable "owners" {
  description = <<EOF
    List of special PostgreSQL DB users - database owners. These users are created first and assigned to database as owner.
    There is also an aditional list for other users with own permissions.

    Required values:
      - name                - (Required) The name of the user.
      - password            - (Optional) The user's password. If it's omitted a random password will be generated.
      - grants              - (Optional) List of the user's grants.
      - login               - (Optional) The user's ability to login.
      - conn_limit          - (Optional) The maximum number of connections per user.
      - settings            - (Optional) A user setting options.
      - deletion_protection - (Optional) A deletion protection.
  EOF
  type = list(object({
    name                = string
    password            = optional(string, null)
    grants              = optional(list(string), [])
    login               = optional(bool, null)
    conn_limit          = optional(number, null)
    settings            = optional(map(any), {})
    deletion_protection = optional(bool, null)
  }))
}

variable "users" {
  description = <<EOF
    List of additional PostgreSQL users with own permissions. They are created at the end.

    Required values:
      - name                - (Required) The name of the user.
      - password            - (Optional) The user's password. If it's omitted a random password will be generated.
      - grants              - (Optional) List of the user's grants.
      - login               - (Optional) The user's ability to login.
      - conn_limit          - (Optional) The maximum number of connections per user.
      - permissions         - (Optional) List of databases names for an access
      - settings            - (Optional) A user setting options.
      - deletion_protection - (Optional) A deletion protection.
  EOF
  type = list(object({
    name                = string
    password            = optional(string, null)
    grants              = optional(list(string), [])
    login               = optional(bool, null)
    conn_limit          = optional(number, null)
    permissions         = optional(list(string), [])
    settings            = optional(map(any), {})
    deletion_protection = optional(bool, null)
  }))
  default = []
}

variable "default_user_settings" {
  description = <<EOF
    The default user settings. These settings are overridden by the user's settings.
    Full description https://cloud.yandex.com/en-ru/docs/managed-postgresql/api-ref/grpc/user_service#UserSettings1
  EOF
  type        = map(any)
  default     = {}
}

variable "pgpass_path" {
  description = <<EOF
    Location of the .pgpass file. If it's omitted the file will not be created
  EOF
  type        = string
  default     = null
}
