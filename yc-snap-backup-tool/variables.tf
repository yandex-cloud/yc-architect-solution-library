variable "create_cron" {
  type        = string
  default     = "0 22 * * ? *"
  description = "Regularity of snapshot creation. Cron expression must be in format like https://cloud.yandex.com/docs/functions/concepts/trigger/timer#cron-expression"
}

variable "delete_cron" {
  type        = string
  default     = "0 23 * * ? *"
  description = "Regularity of deleting expired snapshots. Cron expression must be in format like https://cloud.yandex.com/docs/functions/concepts/trigger/timer#cron-expression"
}
variable "ttl" {
  type        = string
  default     = "604800"
  description = "Snapshot Time To Live in seconds. 1 week = 60*60*24*7 = 604800"
}
variable "mode" {
  type        = string
  default     = "all"
  description = "Function mode: # all # only-marked"
}

variable "service_account_name" {
  description = "Name of service account to create to be used for Cloud Functions."

  type = string

  default = "sa-backup-functions"
}
variable "folder_id" {
  type        = string
  default     = null
  description = "Existing Folder_ID to be used for Cloud Functions. If omiting Folder-ID will be set from yc cli profile"
}

variable "memory" {
  type        = number
  default     = 128
  description = "RAM memory for Cloud Functions"
}

variable "execution_timeout" {
  type        = number
  default     = 30
  description = "Execution_timeout for Cloud Functions"
}
variable "labels" {
  type = map(any)
  default = {
    purpose = "backups"
  }
  description = "Additional lables"
}

