//Create service accounts-------------------

// Service account for DMZ web-server Instange Group
resource "yandex_iam_service_account" "dmz-ig-sa" {
  folder_id = yandex_resourcemanager_folder.folder1.id
  name = "dmz-ig-sa"
}

resource "yandex_resourcemanager_folder_iam_member" "dmz-ig-sa_sa_roles" {
  folder_id = yandex_resourcemanager_folder.folder1.id
  role   = "editor"
  member = "serviceAccount:${yandex_iam_service_account.dmz-ig-sa.id}"
}



//Create Security Groups-------------------

// Create security group for switcher NLB in management segment
resource "yandex_vpc_security_group" "mgmt-sg" {
  name        = "mgmt-sg"
  description = "Security group for mgmt segment"
  folder_id   = yandex_resourcemanager_folder.folder4.id
  network_id  = yandex_vpc_network.vpc_name_4.id

  ingress {
    protocol            = "TCP"
    description         = "NLB healthcheck"
    port                = 443
    predefined_target   = "loadbalancer_healthchecks"
  }

  ingress {
    protocol            = "ANY"
    description         = "internal communications between FW management server and FWs"
    v4_cidr_blocks = [
      "${cidrhost(var.subnet-a_vpc_4, 10)}/32",
      "${cidrhost(var.subnet-b_vpc_4, 10)}/32",
      "${cidrhost(var.subnet-a_vpc_4, 100)}/32"
    ]
  }

  ingress {
    protocol            = "ICMP"
    description         = "ICMP from Jump VM"
    security_group_id   = yandex_vpc_security_group.mgmt-jump-vm-sg.id
  }

  ingress {
    protocol            = "ICMP"
    description         = "ICMP"
    predefined_target   = "self_security_group"
  }  

  ingress {
    protocol            = "TCP"
    description         = "SSH from Jump VM"
    port                = 22
    security_group_id   = yandex_vpc_security_group.mgmt-jump-vm-sg.id
  }

  ingress {
    protocol            = "TCP"
    description         = "Communication from Jump VM between SmartConsole applications and Security Management Server (CPMI)"
    port                = 19009
    security_group_id   = yandex_vpc_security_group.mgmt-jump-vm-sg.id
  }

  ingress {
    protocol            = "TCP"
    description         = "Communication from Jump VM between SmartConsole applications and Security Management Server (CPMI)"
    port                = 18190
    security_group_id   = yandex_vpc_security_group.mgmt-jump-vm-sg.id
  }

  ingress {
    protocol            = "TCP"
    description         = "HTTPS from Jump VM"
    port                = 443
    security_group_id   = yandex_vpc_security_group.mgmt-jump-vm-sg.id
  }

  egress {
    protocol       = "ANY"
    description    = "outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

// Create security group for Jump VM in management segment
resource "yandex_vpc_security_group" "mgmt-jump-vm-sg" {
  name        = "mgmt-jump-vm-sg"
  description = "Security group for Jump VM"
  folder_id   = yandex_resourcemanager_folder.folder4.id
  network_id  = yandex_vpc_network.vpc_name_4.id

  ingress {
    protocol            = "UDP"
    description         = "WireGuard from trusted public IP addresses"
    port                = var.wg_port
    v4_cidr_blocks      = var.trusted_ip_for_access_jump-vm
  }

  ingress {
    protocol            = "TCP"
    description         = "SSH from trusted public IP addresses"
    port                = 22
    v4_cidr_blocks      = var.trusted_ip_for_access_jump-vm
  }

  egress {
    protocol       = "ANY"
    description    = "outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

// Create security groups for ALB FW in public segment
resource "yandex_vpc_security_group" "public-fw-alb-sg" {
  name        = "public-fw-alb-sg"
  description = "Security group to allow NLB healthcheck for primary FW"
  folder_id   = yandex_resourcemanager_folder.folder3.id
  network_id  = yandex_vpc_network.vpc_name_3.id

  ingress {
    protocol            = "TCP"
    description         = "ALB healthcheck"
    port                = 30080
    predefined_target   = "loadbalancer_healthchecks"
  }

  ingress {
    protocol            = "TCP"
    description         = "public app"
    port                = var.public_app_port
    v4_cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "FW-a and FW-b public interfaces IPs"
    v4_cidr_blocks = [
      "${yandex_compute_instance.fw-a.network_interface.1.ip_address}/32", 
      "${yandex_compute_instance.fw-b.network_interface.1.ip_address}/32"
    ]
  }
}

// Create security groups for primary FW in public segment
resource "yandex_vpc_security_group" "public-fw-sg" {
  name        = "public-fw-sg"
  description = "Security group to allow traffic from ALB for public app port"
  folder_id   = yandex_resourcemanager_folder.folder3.id
  network_id  = yandex_vpc_network.vpc_name_3.id

  ingress {
    protocol            = "TCP"
    description         = "from ALB to public app internal port"
    port                = var.internal_app_port
    v4_cidr_blocks      = [var.subnet-a_vpc_3, var.subnet-b_vpc_3]
  }

  egress {
    protocol       = "ANY"
    description    = "outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}


// Create security groups for web-servers in dmz segment
resource "yandex_vpc_security_group" "dmz-web-sg" {
  name        = "dmz-web-sg"
  description = "Security group for web-servers in dmz segment"
  folder_id   = yandex_resourcemanager_folder.folder1.id
  network_id  = yandex_vpc_network.vpc_name_1.id

  ingress {
    protocol            = "ANY"
    description         = "NLB healthcheck for public app internal port"
    port                = var.internal_app_port
    predefined_target   = "loadbalancer_healthchecks"
  }

  ingress {
    protocol            = "TCP"
    description         = "public app internal port"
    port                = var.internal_app_port
    v4_cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    protocol            = "TCP"
    description         = "SSH from management segment"
    port                = 22
    v4_cidr_blocks      = [
      var.subnet-a_vpc_4, 
      var.subnet-b_vpc_4
    ]
  }

 egress {
    protocol       = "ANY"
    description    = "outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

// Create security group for dmz segment
resource "yandex_vpc_security_group" "dmz-sg" {
  name        = "dmz-sg"
  description = "Security group for dmz segment"
  folder_id   = yandex_resourcemanager_folder.folder1.id
  network_id  = yandex_vpc_network.vpc_name_1.id

  ingress {
    protocol            = "TCP"
    description         = "HTTPS"
    port                = 443
    predefined_target   = "self_security_group"
  }

  ingress {
    protocol            = "TCP"
    description         = "SSH"
    port                = 22
    predefined_target   = "self_security_group"
  }

  ingress {
    protocol            = "ICMP"
    description         = "ICMP"
    predefined_target   = "self_security_group"
  }

  ingress {
    protocol            = "ICMP"
    description         = "ICMP from dmz-web-server"
    security_group_id   = yandex_vpc_security_group.dmz-web-sg.id
  }

  egress {
    protocol       = "ANY"
    description    = "outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

// Create security group for app segment
resource "yandex_vpc_security_group" "app-sg" {
  name        = "app-sg"
  description = "Security group for app segment"
  folder_id   = yandex_resourcemanager_folder.folder2.id
  network_id  = yandex_vpc_network.vpc_name_2.id

  ingress {
    protocol            = "TCP"
    description         = "HTTPS"
    port                = 443
    predefined_target   = "self_security_group"
  }

  ingress {
    protocol            = "TCP"
    description         = "SSH"
    port                = 22
    predefined_target   = "self_security_group"
  }

  ingress {
    protocol            = "ICMP"
    description         = "ICMP"
    predefined_target   = "self_security_group"
  }

  egress {
    protocol       = "ANY"
    description    = "outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

// Create security group for database segment
resource "yandex_vpc_security_group" "database-sg" {
  name        = "database-sg"
  description = "Security group for database segment"
  folder_id   = yandex_resourcemanager_folder.folder5.id
  network_id  = yandex_vpc_network.vpc_name_5.id

  ingress {
    protocol            = "TCP"
    description         = "HTTPS"
    port                = 443
    predefined_target   = "self_security_group"
  }

  ingress {
    protocol            = "TCP"
    description         = "SSH"
    port                = 22
    predefined_target   = "self_security_group"
  }

  ingress {
    protocol            = "ICMP"
    description         = "ICMP"
    predefined_target   = "self_security_group"
  }

  egress {
    protocol       = "ANY"
    description    = "outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

// Create security group for VPC 6 segment
resource "yandex_vpc_security_group" "vpc6-sg" {
  name        = "vpc6-sg"
  description = "Security group for vpc6 segment"
  folder_id   = yandex_resourcemanager_folder.folder6.id
  network_id  = yandex_vpc_network.vpc_name_6.id

  ingress {
    protocol            = "TCP"
    description         = "HTTPS"
    port                = 443
    predefined_target   = "self_security_group"
  }

  ingress {
    protocol            = "TCP"
    description         = "SSH"
    port                = 22
    predefined_target   = "self_security_group"
  }

  ingress {
    protocol            = "ICMP"
    description         = "ICMP"
    predefined_target   = "self_security_group"
  }

  egress {
    protocol       = "ANY"
    description    = "outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

// Create security group for VPC 7 segment
resource "yandex_vpc_security_group" "vpc7-sg" {
  name        = "vpc7-sg"
  description = "Security group for vpc7 segment"
  folder_id   = yandex_resourcemanager_folder.folder7.id
  network_id  = yandex_vpc_network.vpc_name_7.id

  ingress {
    protocol            = "TCP"
    description         = "HTTPS"
    port                = 443
    predefined_target   = "self_security_group"
  }

  ingress {
    protocol            = "TCP"
    description         = "SSH"
    port                = 22
    predefined_target   = "self_security_group"
  }

  ingress {
    protocol            = "ICMP"
    description         = "ICMP"
    predefined_target   = "self_security_group"
  }

  egress {
    protocol       = "ANY"
    description    = "outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

// Create security group for VPC 8 segment
resource "yandex_vpc_security_group" "vpc8-sg" {
  name        = "vpc8-sg"
  description = "Security group for vpc8 segment"
  folder_id   = yandex_resourcemanager_folder.folder8.id
  network_id  = yandex_vpc_network.vpc_name_8.id

  ingress {
    protocol            = "TCP"
    description         = "HTTPS"
    port                = 443
    predefined_target   = "self_security_group"
  }

  ingress {
    protocol            = "TCP"
    description         = "SSH"
    port                = 22
    predefined_target   = "self_security_group"
  }

  ingress {
    protocol            = "ICMP"
    description         = "ICMP"
    predefined_target   = "self_security_group"
  }

  egress {
    protocol       = "ANY"
    description    = "outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}