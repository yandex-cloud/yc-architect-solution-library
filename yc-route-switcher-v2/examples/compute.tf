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

resource "random_string" "test_vm_password" {
  length  = 12
  upper   = true
  lower   = true
  numeric  = true
  special = true
  override_special = "!@%&*()-_=+[]{}<>:?"
}

data "yandex_compute_image" "ubuntu_image" {
  family = "ubuntu-2004-lts"
}

data "yandex_compute_image" "nat_instance_image" {
  family = "nat-instance-ubuntu"
}

// create test VM
resource "yandex_compute_instance" "test_vm" {
  folder_id = var.folder_id
  name        = "test-vm"
  hostname    = "test-vm"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_image.id
      type     = "network-hdd"
      size     = 10
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.private_subnet_a.id
    nat        = false
  }

  metadata = {
    user-data = "#cloud-config\nusers:\n  - name: ${var.vm_username}\n    groups: sudo\n    shell: /bin/bash\n    sudo: ['ALL=(ALL) NOPASSWD:ALL']\n    lock_passwd: false\n    hashed_passwd: ${bcrypt(random_string.test_vm_password.result)}\n    ssh-authorized-keys:\n      - ${chomp(tls_private_key.ssh.public_key_openssh)}"
    serial-port-enable = "1"
  }
}

// create NAT-A VM
resource "yandex_compute_instance" "nat_a" {
  folder_id = var.folder_id
  name        = "nat-a"
  hostname    = "nat-a"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.nat_instance_image.id
      type     = "network-hdd"
      size     = 10
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.public_subnet_a.id
    ip_address = "${cidrhost(var.public_subnet_a_cidr, 10)}"
    nat = true
    nat_ip_address = yandex_vpc_address.public_ip_nat_a.external_ipv4_address.0.address
    security_group_ids = [yandex_vpc_security_group.nat_instance_sg.id]
  }

  metadata = {
    user-data = "#cloud-config\nusers:\n  - name: ${var.vm_username}\n    groups: sudo\n    shell: /bin/bash\n    sudo: ['ALL=(ALL) NOPASSWD:ALL']\n    ssh-authorized-keys:\n      - ${chomp(tls_private_key.ssh.public_key_openssh)}"
  }
}


// create NAT-B VM
resource "yandex_compute_instance" "nat_b" {
  folder_id = var.folder_id
  name        = "nat-b"
  hostname    = "nat-b"
  platform_id = "standard-v3"
  zone        = "ru-central1-b"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.nat_instance_image.id
      type     = "network-hdd"
      size     = 10
    }
  }
  
  network_interface {
    subnet_id  = yandex_vpc_subnet.public_subnet_b.id
    ip_address = "${cidrhost(var.public_subnet_b_cidr, 10)}"
    nat = true
    nat_ip_address = yandex_vpc_address.public_ip_nat_b.external_ipv4_address.0.address
    security_group_ids = [yandex_vpc_security_group.nat_instance_sg.id]
  }

  metadata = {
    user-data = "#cloud-config\nusers:\n  - name: ${var.vm_username}\n    groups: sudo\n    shell: /bin/bash\n    sudo: ['ALL=(ALL) NOPASSWD:ALL']\n    ssh-authorized-keys:\n      - ${chomp(tls_private_key.ssh.public_key_openssh)}"
  }
}


