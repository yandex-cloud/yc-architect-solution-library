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
  name               = "ocr-${random_string.suffix.result}"
  runtime            = "python38"
  entrypoint         = "main.handler"
  memory             = "128"
  execution_timeout  = "60"
  service_account_id = yandex_iam_service_account.sa.id

  environment = {
    S3_BUCKET     = yandex_storage_bucket.bucket.id
    S3_PREFIX     = var.s3_prefix_input
    S3_PREFIX_OUT = var.s3_prefix_out
    FOLDER_ID     = var.folder_id
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

resource "yandex_function_trigger" "s3" {
  name        = "ocr-s3-${random_string.suffix.result}"
  description = "ocr-s3-${random_string.suffix.result}"
  
  object_storage {
    bucket_id = yandex_storage_bucket.bucket.id
    prefix    = var.s3_prefix_input
    create    = true
  }

  function {
    id = yandex_function.main.id
    service_account_id = yandex_iam_service_account.sa-invoker.id
  }
}

# Create service account for bucket
resource "yandex_iam_service_account" "sa" {
  folder_id       = var.folder_id
  name            = "ocr-sa-${random_string.suffix.result}"
  description     = "ocr-sa-${random_string.suffix.result}"
}

resource "yandex_resourcemanager_folder_iam_member" "sa-vision-user" {
  folder_id       = var.folder_id
  member          = "serviceAccount:${yandex_iam_service_account.sa.id}"
  role            = "ai.vision.user"
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
  name            = "ocr-sa-invoker-${random_string.suffix.result}"
  description     = "ocr-sa-invoker-${random_string.suffix.result}"
}

resource "yandex_resourcemanager_folder_iam_member" "sa-invoker" {
  folder_id       = var.folder_id
  member          = "serviceAccount:${yandex_iam_service_account.sa-invoker.id}"
  role            = "functions.functionInvoker"
}

# Static access key
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "ocr-${random_string.suffix.result} static key"
}

# Object storage bucket
resource "yandex_storage_bucket" "bucket" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket = "ocr-${random_string.suffix.result}"
}

# API key
resource "yandex_iam_service_account_api_key" "sa-api-key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "ocr-${random_string.suffix.result} API key"
}

# Lockbox
resource "yandex_lockbox_secret" "secret-aws" {
  name = "ocr-aws-${random_string.suffix.result}"
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
  name = "ocr-api-${random_string.suffix.result}"
}

resource "yandex_lockbox_secret_version" "secret-api-v1" {
  secret_id = yandex_lockbox_secret.secret-api.id
  entries {
    key        = "secret_key"
    text_value = yandex_iam_service_account_api_key.sa-api-key.secret_key
  }
}

