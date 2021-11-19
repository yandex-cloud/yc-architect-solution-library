### Datasource
data "yandex_client_config" "client" {}

data "archive_file" "function" {
  type        = "zip"
  source_dir  = "${path.module}/functions/"
  output_path = "${path.module}/build.zip"
}

### Locals
locals {
  folder_id = var.folder_id == null ? data.yandex_client_config.client.folder_id : var.folder_id
}
### IAM
resource "yandex_iam_service_account" "this" {
  name = var.service_account_name
}
resource "yandex_resourcemanager_folder_iam_member" "this" {
  for_each  = toset(["editor", "serverless.functions.invoker"])
  folder_id = local.folder_id
  member    = "serviceAccount:${yandex_iam_service_account.this.id}"
  role      = each.value
}
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.this.id
  description        = "static access key for YMQ"
}
### Cloud Functions 
resource "yandex_function" "spawn-snapshot-tasks" {
  name               = "spawn-snapshot-tasks"
  description        = "Generating tasks for snapshots with cron scheduler and sending to ymq"
  user_hash          = "1.0.0"
  runtime            = "golang116"
  entrypoint         = "spawn-snapshot-tasks.SpawnHandler"
  tags               = ["my_tag"]
  memory             = var.memory
  execution_timeout  = var.execution_timeout
  folder_id          = local.folder_id
  service_account_id = yandex_iam_service_account.this.id
  environment = {
    FOLDER_ID             = local.folder_id
    MODE                  = var.mode
    TTL                   = var.ttl
    QUEUE_URL             = yandex_message_queue.queue.id
    AWS_ACCESS_KEY_ID     = yandex_iam_service_account_static_access_key.sa-static-key.access_key
    AWS_SECRET_ACCESS_KEY = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  }
  content {
    zip_filename = data.archive_file.function.output_path
  }

  labels     = var.labels
  depends_on = [yandex_message_queue.queue]
}

resource "yandex_function" "snapshot-disks" {
  name               = "snapshot-disks"
  description        = "Generating tasks for snapshots with cron scheduler and sending to ymq"
  user_hash          = "1.0.0"
  runtime            = "golang116"
  entrypoint         = "snapshot-disks.SnapshotHandler"
  tags               = ["my_tag"]
  memory             = var.memory
  execution_timeout  = var.execution_timeout
  folder_id          = local.folder_id
  service_account_id = yandex_iam_service_account.this.id
  environment = {
    TTL = var.ttl
  }
  content {
    zip_filename = data.archive_file.function.output_path
  }

  labels     = var.labels
  depends_on = [yandex_message_queue.queue]
}

resource "yandex_function" "delete-expired" {
  name               = "delete-expired"
  description        = "Generating tasks for snapshots with cron scheduler and sending to ymq"
  user_hash          = "1.0.0"
  runtime            = "golang116"
  entrypoint         = "delete-expired.DeleteHandler"
  tags               = ["my_tag"]
  memory             = var.memory
  execution_timeout  = var.execution_timeout
  folder_id          = local.folder_id
  service_account_id = yandex_iam_service_account.this.id
  environment = {
    FOLDER_ID = local.folder_id
  }
  content {
    zip_filename = data.archive_file.function.output_path
  }

  labels     = var.labels
  depends_on = [yandex_message_queue.queue]
}
### Triggers

resource "yandex_function_trigger" "spawn-snapshot-tasks" {
  name        = "spawn-snapshot-tasks"
  description = "Trigger for snapshot backuping system"
  folder_id   = local.folder_id
  timer {
    cron_expression = var.create_cron
  }
  function {
    id                 = yandex_function.spawn-snapshot-tasks.id
    tag                = "$latest"
    service_account_id = yandex_iam_service_account.this.id
  }
}

resource "yandex_function_trigger" "snapshot-disks" {
  name        = "snapshot-disks"
  description = "Trigger for snapshot backuping system"
  folder_id   = local.folder_id
  message_queue {
    queue_id           = yandex_message_queue.queue.arn
    service_account_id = yandex_iam_service_account.this.id
    batch_cutoff       = 1
    batch_size         = 1
  }
  function {
    id                 = yandex_function.snapshot-disks.id
    tag                = "$latest"
    service_account_id = yandex_iam_service_account.this.id
  }

}

resource "yandex_function_trigger" "delete-expired" {
  name        = "delete-expired"
  description = "Trigger for snapshot backuping system"
  folder_id   = local.folder_id
  timer {
    cron_expression = var.delete_cron
  }
  function {
    id                 = yandex_function.delete-expired.id
    tag                = "$latest"
    service_account_id = yandex_iam_service_account.this.id
  }
}

### Message Queue
resource "null_resource" "sleep" {
  provisioner "local-exec" {
    command = "sleep 10"
  }
}
resource "yandex_message_queue" "queue" {
  name                      = "ymq_snapshot_backup"
  receive_wait_time_seconds = 10
  access_key                = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key                = yandex_iam_service_account_static_access_key.sa-static-key.secret_key

  depends_on = [null_resource.sleep, yandex_resourcemanager_folder_iam_member.this, yandex_iam_service_account_static_access_key.sa-static-key]
}
