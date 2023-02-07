// Create passwords for mgmt server (change this after first login)
resource "random_password" "pass-sms" {
  count   = 1
  length  = 10
  special = false
}

// Create SIC activation key (one-time password) between management server and firewalls 
resource "random_password" "pass-sic" {
  count   = 1
  length  = 13
  special = false
}

// Create Check Point FW-A
resource "yandex_compute_instance" "fw-a" {
  folder_id = yandex_resourcemanager_folder.folder4.id
  name        = "fw-a"
  zone        = "ru-central1-a"
  hostname    = "fw-a"
  
  resources {
    cores  = 4
    memory = 8
  }
  
  boot_disk {
    initialize_params {
      image_id = "fd8lv3k0bcm4a5v49mff"
      type     = "network-ssd"
      size     = 120
    }
  }
  
  network_interface {
    // mgmt-int
    subnet_id  = yandex_vpc_subnet.subnet-a_vpc_4.id 
    ip_address = "${cidrhost(var.subnet-a_vpc_4, 10)}"
    nat = false
    security_group_ids = [yandex_vpc_security_group.mgmt-sg.id]
  }
  
  network_interface {
    // public-int
    subnet_id  = yandex_vpc_subnet.subnet-a_vpc_3.id
    ip_address = "${cidrhost(var.subnet-a_vpc_3, 10)}"
    nat = true
    security_group_ids = [yandex_vpc_security_group.public-fw-sg.id]
  }
  
  network_interface {
    // dmz-int
    subnet_id  = yandex_vpc_subnet.subnet-a_vpc_1.id
    ip_address = "${cidrhost(var.subnet-a_vpc_1, 10)}"
    nat = false
    security_group_ids = [yandex_vpc_security_group.dmz-sg.id]
  }
  
  network_interface {
    // app-int
    subnet_id  = yandex_vpc_subnet.subnet-a_vpc_2.id
    ip_address = "${cidrhost(var.subnet-a_vpc_2, 10)}"
    nat = false
    security_group_ids = [yandex_vpc_security_group.app-sg.id]
  }
  
  network_interface {
    // database-int
    subnet_id  = yandex_vpc_subnet.subnet-a_vpc_5.id
    ip_address = "${cidrhost(var.subnet-a_vpc_5, 10)}"
    nat = false
    security_group_ids = [yandex_vpc_security_group.database-sg.id]
  }
  
  network_interface {
    // vpc6-int
    subnet_id  = yandex_vpc_subnet.subnet-a_vpc_6.id
    ip_address = "${cidrhost(var.subnet-a_vpc_6, 10)}"
    nat = false
    security_group_ids = [yandex_vpc_security_group.vpc6-sg.id]
  }
  
  network_interface {
    // vpc7-int
    subnet_id  = yandex_vpc_subnet.subnet-a_vpc_7.id
    ip_address = "${cidrhost(var.subnet-a_vpc_7, 10)}"
    nat = false
    security_group_ids = [yandex_vpc_security_group.vpc7-sg.id]
  }
  
  network_interface {
    // vpc8-int
    subnet_id  = yandex_vpc_subnet.subnet-a_vpc_8.id
    ip_address = "${cidrhost(var.subnet-a_vpc_8, 10)}"
    nat = false
    security_group_ids = [yandex_vpc_security_group.vpc8-sg.id]
  }

  metadata = {
    serial-port-enable = 1
    user-data = templatefile("./templates/check-init_gw-a.tpl.yaml",
    {
      ssh_key = "${chomp(tls_private_key.ssh.public_key_openssh)}"
      pass_sic = "${random_password.pass-sic[0].result}"
      static-routes = {
        "${var.subnet-b_vpc_1}" = "${cidrhost(var.subnet-a_vpc_1, 1)}"
        "${var.subnet-b_vpc_2}" = "${cidrhost(var.subnet-a_vpc_2, 1)}"
        "${var.subnet-b_vpc_4}" = "${cidrhost(var.subnet-a_vpc_4, 1)}"
        "${var.subnet-b_vpc_5}" = "${cidrhost(var.subnet-a_vpc_5, 1)}"
        "${var.subnet-b_vpc_6}" = "${cidrhost(var.subnet-a_vpc_6, 1)}"
        "${var.subnet-b_vpc_7}" = "${cidrhost(var.subnet-a_vpc_7, 1)}"
        "${var.subnet-b_vpc_8}" = "${cidrhost(var.subnet-a_vpc_8, 1)}"
        "198.18.235.0/24"       = "${cidrhost(var.subnet-a_vpc_4, 1)}"
        "198.18.248.0/24"       = "${cidrhost(var.subnet-a_vpc_4, 1)}"
      }
      gw = "${cidrhost(var.subnet-a_vpc_3, 1)}"
    })
  }
}

// Create Check Point FW-B
resource "yandex_compute_instance" "fw-b" {
  folder_id = yandex_resourcemanager_folder.folder4.id
  name        = "fw-b"
  zone        = "ru-central1-b"
  hostname    = "fw-b"
  
  resources {
    cores  = 4
    memory = 8
  }
  
  boot_disk {
    initialize_params {
      image_id = "fd8lv3k0bcm4a5v49mff"
      type     = "network-ssd"
      size     = 120
    }
  }
  
  network_interface {
    // mgmt-int
    subnet_id  = yandex_vpc_subnet.subnet-b_vpc_4.id 
    ip_address = "${cidrhost(var.subnet-b_vpc_4, 10)}"
    nat = false
    security_group_ids = [yandex_vpc_security_group.mgmt-sg.id]
  }
  
  network_interface {
    // public-int
    subnet_id  = yandex_vpc_subnet.subnet-b_vpc_3.id
    ip_address = "${cidrhost(var.subnet-b_vpc_3, 10)}"
    nat = true
    security_group_ids = [yandex_vpc_security_group.public-fw-sg.id]
  }
  
  network_interface {
    // dmz-int
    subnet_id  = yandex_vpc_subnet.subnet-b_vpc_1.id
    ip_address = "${cidrhost(var.subnet-b_vpc_1, 10)}"
    nat = false
    security_group_ids = [yandex_vpc_security_group.dmz-sg.id]
  }
  
  network_interface {
    // app-int
    subnet_id  = yandex_vpc_subnet.subnet-b_vpc_2.id
    ip_address = "${cidrhost(var.subnet-b_vpc_2, 10)}"
    nat = false
    security_group_ids = [yandex_vpc_security_group.app-sg.id]
  }
  
  network_interface {
    // database-int
    subnet_id  = yandex_vpc_subnet.subnet-b_vpc_5.id
    ip_address = "${cidrhost(var.subnet-b_vpc_5, 10)}"
    nat = false
    security_group_ids = [yandex_vpc_security_group.database-sg.id]
  }
  
  network_interface {
    // vpc6-int
    subnet_id  = yandex_vpc_subnet.subnet-b_vpc_6.id
    ip_address = "${cidrhost(var.subnet-b_vpc_6, 10)}"
    nat = false
    security_group_ids = [yandex_vpc_security_group.vpc6-sg.id]
  }
  
  network_interface {
    // vpc7-int
    subnet_id  = yandex_vpc_subnet.subnet-b_vpc_7.id
    ip_address = "${cidrhost(var.subnet-b_vpc_7, 10)}"
    nat = false
    security_group_ids = [yandex_vpc_security_group.vpc7-sg.id]
  }

  network_interface {
    // vpc8-int
    subnet_id  = yandex_vpc_subnet.subnet-b_vpc_8.id
    ip_address = "${cidrhost(var.subnet-b_vpc_8, 10)}"
    nat = false
    security_group_ids = [yandex_vpc_security_group.vpc8-sg.id]
  }

  metadata = {
    serial-port-enable = 1
    user-data = templatefile("./templates/check-init_gw-b.tpl.yaml",
    {
      ssh_key = "${chomp(tls_private_key.ssh.public_key_openssh)}"
      pass_sic = "${random_password.pass-sic[0].result}"
      static-routes = {
        "${var.subnet-a_vpc_1}" = "${cidrhost(var.subnet-b_vpc_1, 1)}"
        "${var.subnet-a_vpc_2}" = "${cidrhost(var.subnet-b_vpc_2, 1)}"
        "${var.subnet-a_vpc_4}" = "${cidrhost(var.subnet-b_vpc_4, 1)}"
        "${var.subnet-a_vpc_5}" = "${cidrhost(var.subnet-b_vpc_5, 1)}"
        "${var.subnet-a_vpc_6}" = "${cidrhost(var.subnet-b_vpc_6, 1)}"
        "${var.subnet-a_vpc_7}" = "${cidrhost(var.subnet-b_vpc_7, 1)}"
        "${var.subnet-a_vpc_8}" = "${cidrhost(var.subnet-b_vpc_8, 1)}"
        "198.18.235.0/24"       = "${cidrhost(var.subnet-b_vpc_4, 1)}"
        "198.18.248.0/24"       = "${cidrhost(var.subnet-b_vpc_4, 1)}"
      }
      gw = "${cidrhost(var.subnet-b_vpc_3, 1)}"
    })
  }
}

//Create Check Point management server
resource "yandex_compute_instance" "mgmt-server" {
  folder_id = yandex_resourcemanager_folder.folder4.id
  name        = "mgmt-server"
  zone        = "ru-central1-a"
  hostname    = "mgmt-server"
  
  resources {
    cores  = 4
    memory = 8
  }
  boot_disk {
    initialize_params {
      image_id = "fd8hcf4gjv3adselqajo"
      type     = "network-ssd"
      size     = 120
    }
  }

  network_interface {
    // mgmt-int
    subnet_id  = yandex_vpc_subnet.subnet-a_vpc_4.id
    ip_address = "${cidrhost(var.subnet-a_vpc_4, 100)}"
    nat = false
    security_group_ids = [yandex_vpc_security_group.mgmt-sg.id]
  }

  metadata = {
    serial-port-enable = 1
    user-data = templatefile("./templates/check-init-sms.tpl.yaml",
    {
      ssh_key = "${chomp(tls_private_key.ssh.public_key_openssh)}",
      pass = "${random_password.pass-sms[0].result}"
    })
  }
}