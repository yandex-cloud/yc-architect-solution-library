data "archive_file" "route_switcher_function" {
  type        = "zip"
  source_dir  = "${path.module}/route-switcher-function/"
  output_path = "${path.module}/route-switcher-function.zip"
}

resource "yandex_function" "route-switcher" {
  folder_id          = var.folder_id
  name               = "route-switcher-${random_string.prefix.result}"
  description        = "route-switcher function"
  runtime            = "python38"
  entrypoint         = "main.handler"
  memory             = "128"
  execution_timeout  = "600"
  service_account_id = yandex_iam_service_account.route_switcher_sa.id
  environment = {
    AWS_ACCESS_KEY_ID     = yandex_iam_service_account_static_access_key.route_switcher_sa_s3_keys.access_key
    AWS_SECRET_ACCESS_KEY = yandex_iam_service_account_static_access_key.route_switcher_sa_s3_keys.secret_key
    BUCKET_NAME           = yandex_storage_bucket.route_switcher_bucket.id
    CONFIG_PATH           = "route-switcher-config.yaml"
    CRON_INTERVAL         = var.cron_interval
    BACK_TO_PRIMARY       = var.back_to_primary
  }
  user_hash = data.archive_file.route_switcher_function.output_base64sha256
  content {
    zip_filename = data.archive_file.route_switcher_function.output_path
  }
}

resource "yandex_function_trigger" "route_switcher_trigger" {
  folder_id = var.folder_id
  name = "route-switcher-trigger-${random_string.prefix.result}"
  count = var.start_module ? 1 : 0

  function {
    id                 = yandex_function.route-switcher.id
    service_account_id = yandex_iam_service_account.route_switcher_sa.id
  }

  timer {
    cron_expression = "* * * * ? *"
  }
}
