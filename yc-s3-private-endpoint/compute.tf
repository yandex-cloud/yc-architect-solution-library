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
  family = "nat-instance-ubuntu-2204"
}
// create NAT instances
resource "yandex_compute_instance" "nat_vm" {
  count       = var.nat_instances_count
  folder_id   = var.folder_id
  name        = "nat-${substr(var.yc_availability_zones[count.index % length(var.yc_availability_zones)], -1, -1)}${floor(count.index / length(var.yc_availability_zones)) + 1}-vm"
  hostname    = "nat-${substr(var.yc_availability_zones[count.index % length(var.yc_availability_zones)], -1, -1)}${floor(count.index / length(var.yc_availability_zones)) + 1}-vm"
  platform_id = "standard-v3"
  zone        = var.yc_availability_zones[count.index % length(var.yc_availability_zones)]

  resources {
    cores     = 2
    memory    = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.nat_instance_image.id
      type     = "network-ssd"
      size     = 10
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.nat_vm_subnets[count.index % length(var.yc_availability_zones)].id
    nat        = true
    nat_ip_address = yandex_vpc_address.public_ip_list[count.index].external_ipv4_address.0.address
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
        access_key = yandex_iam_service_account_static_access_key.s3_bucket_sa_keys.access_key,
        secret_key = yandex_iam_service_account_static_access_key.s3_bucket_sa_keys.secret_key
        bucket = yandex_storage_bucket.s3_bucket.bucket
      })
    serial-port-enable = "1"
  }
}

