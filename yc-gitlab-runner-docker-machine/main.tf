data "yandex_client_config" "client" {}

resource "yandex_iam_service_account" "gitlab_docker_machine" {
  name        = "gitlab-docker-machine"
  folder_id   = local.folder_id
  description = "gitlab-docker-machine SA"
}

resource "yandex_resourcemanager_folder_iam_member" "gitlab_docker_machine_roles" {
  for_each  = toset(["compute.admin", "vpc.user", "lockbox.payloadViewer"])
  folder_id = local.folder_id

  role   = each.key
  member = "serviceAccount:${yandex_iam_service_account.gitlab_docker_machine.id}"
}

resource "yandex_kms_symmetric_key_iam_binding" "gitlab_docker_machine_kms_roles" {
  symmetric_key_id = yandex_kms_symmetric_key.gitlab_token_key.id

  role = "kms.keys.encrypterDecrypter"
  members = [
    "serviceAccount:${yandex_iam_service_account.gitlab_docker_machine.id}"
  ]
}

data "yandex_compute_image" "ubuntu_lts" {
  family = "ubuntu-2204-lts"
}

resource "yandex_compute_instance" "gitlab_docker_machine" {
  name                      = "gitlab-docker-machine"
  hostname                  = "gitlab-docker-machine"
  platform_id               = "standard-v3"
  zone                      = var.default_zone
  folder_id                 = local.folder_id
  allow_stopping_for_update = true

  service_account_id = yandex_iam_service_account.gitlab_docker_machine.id
  resources {
    cores         = 2
    memory        = 2
    core_fraction = 50
  }

  boot_disk {
    auto_delete = true
    initialize_params {
      image_id   = data.yandex_compute_image.ubuntu_lts.id
      block_size = 4096
      size       = 20
      type       = "network-ssd"
    }
  }

  network_interface {
    subnet_id          = local.subnet_id
    nat                = true
    security_group_ids = var.security_group_create ? [yandex_vpc_security_group.securtiy_group_master[0].id] : null
  }

  metadata = {
    user-data          = <<-USERDATA
      #cloud-config
      users:
        - name: ${var.username}
          groups: sudo
          shell: /bin/bash
          sudo: ['ALL=(ALL) NOPASSWD:ALL']
          ssh-authorized-keys:
            - ${file(var.user_pubkey_filename)}
      write_files:
        - path: /root/postinstall.sh
          owner: root:root
          permissions: 0o750
          encoding: base64
          defer: true
          content: |
            ${filebase64("${path.module}/files/postinstall.sh")}
        - path: /root/gitlab-runner-config.toml
          owner: root:root
          permissions: 0o640
          encoding: base64
          defer: true
          content: |
            ${base64encode(templatefile("${path.module}/files/gitlab-runner-config.tftpl", local.template_vars))}
        - path: /root/secret_id
          owner: root:root
          permissions: 0o600
          encoding: base64
          defer: true
          content: |
            ${base64encode(yandex_lockbox_secret.gitlab_token.id)}
      runcmd:
        - [ bash, /root/postinstall.sh ]
    USERDATA
    serial-port-enable = 0
  }

  scheduling_policy {
    preemptible = false
  }

  depends_on = [
    yandex_resourcemanager_folder_iam_member.gitlab_docker_machine_roles,
    yandex_lockbox_secret_version.gitlab_token_version
  ]
}

