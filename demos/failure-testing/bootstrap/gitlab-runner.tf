module "gitlab_runner" {
  count  = var.gitlab_runner_enabled == true ? 1 : 0
  source = "../modules/gitlab-runner"

  folder_id                 = local.folder_id
  gitlab_registration_token = local.gitlab_project.runners_token
  gitlab_url                = var.gitlab_url
  worker_cores              = 2
  worker_memory             = 4

  network_create = true
  sa_name        = "gitlab-docker-machine${local.name_suffix}"
  #  user_pubkey_filename      = "~/.ssh/id_rsa.pub"
  #  username                  = "ubuntu"
  #  worker_image_id           = "fd8xxxxxxxxxxxx"
}
