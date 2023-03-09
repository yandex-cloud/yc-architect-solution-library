# Various
data "archive_file" "function" {
  type        = "zip"
  source_dir  = "${path.module}/functions"
  output_path = "${path.module}/functions.zip"
}

resource "random_string" "suffix" {
  length  = 8
  upper   = false
  lower   = true
  number  = true
  special = false
}

# Cloud Function
resource "yandex_function" "main" {
  folder_id          = var.folder_id
  name               = "asr-batch-${random_string.suffix.result}"
  runtime            = "python38"
  entrypoint         = "main.handler"
  memory             = "128"
  execution_timeout  = "60"
  service_account_id = yandex_iam_service_account.sa.id

  environment = {
    S3_BUCKET     = yandex_storage_bucket.bucket.id
    S3_PREFIX     = var.s3_prefix_input
    S3_PREFIX_LOG = var.s3_prefix_log
    S3_PREFIX_OUT = var.s3_prefix_out
  }

  secrets {
    id                   = yandex_lockbox_secret.secret-aws.id
    version_id           = yandex_lockbox_secret_version.secret-aws-v1.id
    key                  = "access_key"
    environment_variable = "S3_KEY"
  }

  secrets {
    id                   = yandex_lockbox_secret.secret-aws.id
    version_id           = yandex_lockbox_secret_version.secret-aws-v1.id
    key                  = "secret_key"
    environment_variable = "S3_SECRET"
  }

  secrets {
    id                   = yandex_lockbox_secret.secret-api.id
    version_id           = yandex_lockbox_secret_version.secret-api-v1.id
    key                  = "secret_key"
    environment_variable = "API_SECRET"
  }

  user_hash = data.archive_file.function.output_base64sha256
  content {
    zip_filename = data.archive_file.function.output_path
  }
}

resource "yandex_function_trigger" "cron" {
  name        = "asr-batch-cron-${random_string.suffix.result}"
  description = "asr-batch-cron-${random_string.suffix.result}"
  timer {
    cron_expression = "0/3 * * * ? *"
  }
  function {
    id = yandex_function.main.id
    service_account_id = yandex_iam_service_account.sa-invoker.id
  }
}

# Create service account for bucket
resource "yandex_iam_service_account" "sa" {
  folder_id       = var.folder_id
  name            = "asr-batch-sa-${random_string.suffix.result}"
  description     = "asr-batch-sa-${random_string.suffix.result}"
}

resource "yandex_resourcemanager_folder_iam_member" "sa-stt-user" {
  folder_id       = var.folder_id
  member          = "serviceAccount:${yandex_iam_service_account.sa.id}"
  role            = "ai.speechkit-stt.user"
}

resource "yandex_resourcemanager_folder_iam_member" "sa-storage-editor" {
  folder_id       = var.folder_id
  member          = "serviceAccount:${yandex_iam_service_account.sa.id}"
  role            = "storage.editor"
}

resource "yandex_resourcemanager_folder_iam_member" "sa-lockbox-payload" {
  folder_id       = var.folder_id
  member          = "serviceAccount:${yandex_iam_service_account.sa.id}"
  role            = "lockbox.payloadViewer"
}

# Create service account for function trigger
resource "yandex_iam_service_account" "sa-invoker" {
  folder_id       = var.folder_id
  name            = "asr-batch-sa-invoker-${random_string.suffix.result}"
  description     = "asr-batch-sa-invoker-${random_string.suffix.result}"
}

resource "yandex_resourcemanager_folder_iam_member" "sa-invoker" {
  folder_id       = var.folder_id
  member          = "serviceAccount:${yandex_iam_service_account.sa-invoker.id}"
  role            = "functions.functionInvoker"
}

# Static access key
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "asr-batch-${random_string.suffix.result} static key"
}

# Object storage bucket
resource "yandex_storage_bucket" "bucket" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket = "asr-batch-${random_string.suffix.result}"
}

resource "yandex_storage_object" "config-json" {
  bucket = yandex_storage_bucket.bucket.id
  key    = "${var.s3_prefix_input}/config.json"
  content_type = "application/json"
  content_base64 = "ewogICAgImxhbmciOiAicnUtUlUiCn0="
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
}

# API key
resource "yandex_iam_service_account_api_key" "sa-api-key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "asr-batch-${random_string.suffix.result} API key"
}

# Lockbox
resource "yandex_lockbox_secret" "secret-aws" {
  name = "asr-batch-aws-${random_string.suffix.result}"
}

resource "yandex_lockbox_secret_version" "secret-aws-v1" {
  secret_id = yandex_lockbox_secret.secret-aws.id
  entries {
    key        = "access_key"
    text_value = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  }
  entries {
    key        = "secret_key"
    text_value = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  }
}

resource "yandex_lockbox_secret" "secret-api" {
  name = "asr-batch-api-${random_string.suffix.result}"
}

resource "yandex_lockbox_secret_version" "secret-api-v1" {
  secret_id = yandex_lockbox_secret.secret-api.id
  entries {
    key        = "secret_key"
    text_value = yandex_iam_service_account_api_key.sa-api-key.secret_key
  }
}

