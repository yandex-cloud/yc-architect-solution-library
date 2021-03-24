

data "archive_file" "function" {
  type        = "zip"
  source_dir  = "${path.module}/function"
  output_path = "${path.module}/sync.zip"
}

resource "yandex_function" "route_switcher" {
  folder_id          = var.folder_id
  name               = "route-switcher-${var.vpc_id}"
  runtime            = "python38"
  entrypoint         = "main.handler"
  memory             = "128"
  execution_timeout  = "30"
  service_account_id = var.sa_id
  environment = {
    AWS_ACCESS_KEY_ID     = var.access_key
    AWS_SECRET_ACCESS_KEY = var.secret_key
    BUCKET_NAME           = var.bucket_id
    CONFIG_PATH           = "config-${var.vpc_id}.yaml"
  }
  user_hash = data.archive_file.function.output_base64sha256
  content {
    zip_filename = data.archive_file.function.output_path
  }
}

resource "yandex_function_trigger" "route_switcher" {
  folder_id = var.folder_id

  name = "route-swicher-${var.vpc_id}"

  function {
    id                 = yandex_function.route_switcher.id
    service_account_id = var.sa_id
  }

  timer {
    cron_expression = "* * * * ? *"
  }
}
