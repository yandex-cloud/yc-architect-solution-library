locals {
  gitlab_project =  var.gitlab_project_id == null ? gitlab_project.this.0 : data.gitlab_project.this.0
  gitlab_var_create = var.gitlab_enabled == true && var.gitlab_env_vars_setup == true ? 1 : 0
}

provider "gitlab" {
  token    = var.gitlab_access_token
  base_url = "${var.gitlab_url}/api/v4/"
}

data "gitlab_user" "user" {
  username = var.gitlab_username
}

resource "gitlab_project" "this" {
  count               = var.gitlab_enabled == true && var.gitlab_project_id == null ? 1 : 0
  name                = "failure-testing"
  description         = "Failure testing project"
  namespace_id        = data.gitlab_user.user.namespace_id
  import_url          = "${var.gitlab_url}/gitops/chaos.git"
  import_url_username = var.gitlab_username
  import_url_password = var.gitlab_access_token
  lifecycle {
      prevent_destroy = true
  }
}

data "gitlab_project" "this" {
  count = var.gitlab_project_id == null ? 0 : 1
  id    = var.gitlab_project_id
}

resource "gitlab_project_variable" "folder_id" {
  count     = local.gitlab_var_create
  project   = local.gitlab_project.id
  key       = "TF_VAR_folder_id"
  value     = local.folder_id
  protected = true
}

resource "gitlab_project_variable" "network_id" {
  count     = local.gitlab_var_create
  project   = local.gitlab_project.id
  key       = "TF_VAR_network_id"
  value     = local.network_id
  protected = true
}

resource "gitlab_project_variable" "ip_addr" {
  count     = local.gitlab_var_create
  project   = local.gitlab_project.id
  key       = "TF_VAR_ip_addr"
  value     = local.ip_addr
  protected = true
}

resource "gitlab_project_variable" "cr_id" {
  count     = local.gitlab_var_create
  project   = local.gitlab_project.id
  key       = "TF_VAR_cr_id"
  value     = local.cr_id
  protected = true
}

resource "gitlab_project_variable" "cert_id" {
  count     = local.gitlab_var_create
  project   = local.gitlab_project.id
  key       = "TF_VAR_cert_id"
  value     = yandex_cm_certificate.le_cert.id
  protected = true
}

resource "gitlab_project_variable" "fqdn" {
  count     = local.gitlab_var_create
  project   = local.gitlab_project.id
  key       = "TF_VAR_fqdn"
  value     = local.fqdn
  protected = true
}

resource "gitlab_project_variable" "tf_cli_config_file" {
  count         = local.gitlab_var_create
  project       = local.gitlab_project.id
  key           = "TF_CLI_CONFIG_FILE"
  value         = <<-EOF
    provider_installation {
      network_mirror {
        url = "https://terraform-mirror.yandexcloud.net/"
        include = ["registry.terraform.io/*/*"]
      }
      direct {
        exclude = ["registry.terraform.io/*/*"]
      }
    }
  EOF
  protected     = true
  variable_type = "file"
}

resource "gitlab_project_variable" "yc_service_account_key_file" {
  count   = local.gitlab_var_create
  project = local.gitlab_project.id
  key     = "YC_SERVICE_ACCOUNT_KEY_FILE"
  value = jsonencode(
    {
      "id" : yandex_iam_service_account_key.ft_owner.0.id,
      "service_account_id" : yandex_iam_service_account_key.ft_owner.0.service_account_id,
      "created_at" : yandex_iam_service_account_key.ft_owner.0.created_at,
      "key_algorithm" : yandex_iam_service_account_key.ft_owner.0.key_algorithm,
      "public_key" : yandex_iam_service_account_key.ft_owner.0.public_key,
      "private_key" : yandex_iam_service_account_key.ft_owner.0.private_key
    }
  )
  protected     = true
  variable_type = "file"
}

resource "gitlab_project_variable" "ci_registry" {
  count     = local.gitlab_var_create
  project   = local.gitlab_project.id
  key       = "CI_REGISTRY"
  value     = local.cr
  protected = true
}

resource "gitlab_project_variable" "ci_registry_key" {
  count   = local.gitlab_var_create
  project = local.gitlab_project.id
  key     = "CI_REGISTRY_KEY"
  value = jsonencode(
    {
      "id" : yandex_iam_service_account_key.cr_pusher.0.id,
      "service_account_id" : yandex_iam_service_account_key.cr_pusher.0.service_account_id,
      "created_at" : yandex_iam_service_account_key.cr_pusher.0.created_at,
      "key_algorithm" : yandex_iam_service_account_key.cr_pusher.0.key_algorithm,
      "public_key" : yandex_iam_service_account_key.cr_pusher.0.public_key,
      "private_key" : yandex_iam_service_account_key.cr_pusher.0.private_key
    }
  )
  protected = true
}

resource "gitlab_project_variable" "name_suffix" {
  count     = local.gitlab_var_create
  project   = local.gitlab_project.id
  key       = "TF_VAR_name_suffix"
  value     = random_string.uniq.0.id
  protected = true
}
