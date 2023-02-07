// Create ssh keys for compute resources
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "pt_key.pem"
  file_permission = "0600"
}

// Create Jump VM
resource "yandex_compute_instance" "jump-vm" {
  folder_id = yandex_resourcemanager_folder.folder4.id
  name        = "jump-vm"
  hostname    = "jump-vm"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8smb7fj0o91i68s15v"
      type     = "network-hdd"
      size     = 10
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.subnet-a_vpc_4.id
    ip_address = "${cidrhost(var.subnet-a_vpc_4, 101)}"
    nat                = true
    nat_ip_address = yandex_vpc_address.public-ip-jump-vm.external_ipv4_address.0.address
    security_group_ids = [yandex_vpc_security_group.mgmt-jump-vm-sg.id] 
  }

  metadata = {
    user-data = templatefile("./templates/cloud-init_jump-vm.tpl.yaml",
    {
      jump_vm_ssh_key_pub = "${chomp(tls_private_key.ssh.public_key_openssh)}",
      jump_vm_admin_username = var.jump_vm_admin_username,
      wg_port           = var.wg_port,
      wg_client_dns     = "${cidrhost(var.subnet-a_vpc_4, 2)}, ${cidrhost(var.subnet-b_vpc_4, 2)}",
      wg_public_ip      = "${yandex_vpc_address.public-ip-jump-vm.external_ipv4_address.0.address}",
      wg_allowed_ip     = "${var.subnet-a_vpc_1}, ${var.subnet-b_vpc_1}, ${var.subnet-a_vpc_2}, ${var.subnet-b_vpc_2}, ${var.subnet-a_vpc_4}, ${var.subnet-b_vpc_4}, ${var.subnet-a_vpc_5}, ${var.subnet-b_vpc_5}"
    })
  }
}

// Wait for SSH connection to Jump VM 
resource "null_resource" "wait_for_ssh_jump_vm" {
  connection {
    type = "ssh"
    user = "${var.jump_vm_admin_username}"
    private_key = local_file.private_key.content
    host = yandex_vpc_address.public-ip-jump-vm.external_ipv4_address.0.address
  }
 
 // Wait for WireGuard client config to be updated with keys in cloud-init process
  provisioner "remote-exec" {
    inline = [
      "while [ ! -f ~/jump-vm-wg.conf ]; do sleep 5; echo \"Waiting for jump-vm-wg.conf to be created...\"; done",
      "while grep -q CLIENT_PSK ~/jump-vm-wg.conf; do sleep 5; echo \"Waiting for jump-vm-wg.conf to be updated with keys...\"; done"
    ]
  }
 
  depends_on = [
    yandex_compute_instance.jump-vm,
    local_file.private_key,
    yandex_vpc_address.public-ip-jump-vm
  ]
}

// Download WireGuard client config from Jump VM
resource "null_resource" "get_wg_client_config" {
  provisioner "local-exec" {
    command = "scp -i pt_key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${var.jump_vm_admin_username}@${yandex_vpc_address.public-ip-jump-vm.external_ipv4_address.0.address}:jump-vm-wg.conf jump-vm-wg.conf"
  }
 
  depends_on = [
    null_resource.wait_for_ssh_jump_vm
  ]
}

// Instance group for web-server in dmz segment
resource "yandex_compute_instance_group" "dmz-web-server-ig" {
  name                = "dmz-web-server-ig"
  folder_id           = yandex_resourcemanager_folder.folder1.id
  service_account_id  = yandex_iam_service_account.dmz-ig-sa.id
  depends_on = [ yandex_resourcemanager_folder_iam_member.dmz-ig-sa_sa_roles ]

  instance_template {
    platform_id = "standard-v3"
    
    resources {
      memory = 2
      cores  = 2
    }
    
    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = "fd8scqsds5me81jjilu9"
        size     = 10
      }
    }
    
    network_interface {
      network_id = yandex_vpc_network.vpc_name_1.id
      subnet_ids = [yandex_vpc_subnet.subnet-a_vpc_1.id, yandex_vpc_subnet.subnet-b_vpc_1.id]
      nat = false
      security_group_ids = [yandex_vpc_security_group.dmz-web-sg.id]
    }
    
    metadata = {
      user-data = templatefile("./templates/cloud-init_dmz-web-server.tpl.yaml",
        {
          ssh_key_pub = "${chomp(tls_private_key.ssh.public_key_openssh)}",
          nginx_port  = var.internal_app_port,
        })
      ssh-keys = "ubuntu:${chomp(tls_private_key.ssh.public_key_openssh)}"
    }
  }

  scale_policy {
    auto_scale {
      initial_size = 2
      measurement_duration = 60
      cpu_utilization_target = 75
      min_zone_size = 1
      max_size = 4
    }
  }

  allocation_policy {
    zones = ["ru-central1-a", "ru-central1-b"]
  }

  deploy_policy {
    max_unavailable = 0
    max_creating    = 2
    max_expansion   = 2
    max_deleting    = 1
  }

  load_balancer {
    target_group_name = "dmz-web-server-nlb-tg"
  }
}
