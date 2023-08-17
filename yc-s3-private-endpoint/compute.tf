// create ssh keys for compute resources
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "pt_key.pem"
  file_permission = "0600"
}

resource "random_password" "test_vm_password" {
  length  = 12
  upper   = true
  lower   = true
  numeric  = true
  special = true
  override_special = "!@%&*()-_=+[]{}<>:?"
}

data "yandex_compute_image" "toolbox_image" {
  family = "toolbox"
}

data "yandex_compute_image" "nat_instance_image" {
  family = "nat-instance-ubuntu"
}

// Instance group for NAT instances
resource "yandex_compute_instance_group" "nat_instances_ig" {
  name                = "s3-nat-ig"
  folder_id           = var.folder_id
  service_account_id  = yandex_iam_service_account.nat_ig_sa.id
  depends_on = [ yandex_resourcemanager_folder_iam_member.nat_ig_sa_roles ]

  instance_template {
    platform_id = "standard-v3"
    
    resources {
      memory = 2
      cores  = 2
    }
    
    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = data.yandex_compute_image.nat_instance_image.id
        type     = "network-hdd"
        size     = 10
      }
    }
    
    network_interface {
      network_id = var.vpc_id == null ? yandex_vpc_network.vpc[0].id : var.vpc_id
      subnet_ids = length(var.subnet_id_list) == 0 ? yandex_vpc_subnet.nat_instances_subnets.*.id : var.subnet_id_list
      nat = true
      security_group_ids = [yandex_vpc_security_group.nat_sg.id]
    }
    
    metadata = {
      user-data = templatefile("./templates/cloud-init_nat_instance.tpl.yaml",
        {
          ssh_key_pub = "${chomp(tls_private_key.ssh.public_key_openssh)}",
          username  = var.vm_username,
          s3_ip = var.s3_ip
        })
    }
  }

  scale_policy {
    fixed_scale {
      size = var.nat_instances_count
    }
  }

  allocation_policy {
    zones = var.yc_availability_zones
  }

  deploy_policy {
    max_unavailable = 1
    max_creating    = 2
    max_expansion   = 0
    startup_duration = 60
  }

  load_balancer {
    target_group_name = "s3-nlb-tg"
  }
}

// create test VM
resource "yandex_compute_instance" "test_vm" {
  folder_id = var.folder_id
  name        = "test-s3-vm"
  hostname    = "test-s3-vm"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.toolbox_image.id
      type     = "network-hdd"
      size     = 30
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.test_subnet.id
    ip_address = "${cidrhost(yandex_vpc_subnet.test_subnet.v4_cidr_blocks[0], 50)}"
    nat        = false
  }

  metadata = {
    user-data = templatefile("./templates/cloud-init_test_vm.tpl.yaml",
      {
        ssh_key_pub = chomp(tls_private_key.ssh.public_key_openssh),
        username  = var.vm_username,
        vm_password = random_password.test_vm_password.bcrypt_hash,
        access_key = yandex_iam_service_account_static_access_key.s3_test_bucket_sa_keys.access_key,
        secret_key = yandex_iam_service_account_static_access_key.s3_test_bucket_sa_keys.secret_key
      })
    serial-port-enable = "1"
  }
}





