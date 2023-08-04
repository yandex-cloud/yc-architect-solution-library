resource "yandex_kms_symmetric_key" "gitlab_token_key" {
  name              = "gitlab-token-key"
  folder_id         = local.folder_id
  description       = "gitlab token ecryption key"
  default_algorithm = "AES_256"
  rotation_period   = "8760h"
}

resource "yandex_lockbox_secret" "gitlab_token" {
  folder_id  = local.folder_id
  name       = "Gitlab token"
  kms_key_id = yandex_kms_symmetric_key.gitlab_token_key.id
}

resource "yandex_lockbox_secret_version" "gitlab_token_version" {
  secret_id = yandex_lockbox_secret.gitlab_token.id
  entries {
    key        = "gitlab_token"
    text_value = var.gitlab_registration_token
  }
  entries {
    key        = "gitlab_url"
    text_value = var.gitlab_url
  }
  entries {
    key        = "gitlab_runner_tags"
    text_value = var.gitlab_runner_tags == "" ? "-" : var.gitlab_runner_tags
  }
}
