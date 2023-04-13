// Create static routes-------------------

// Create static routes for dmz vpc
resource "yandex_vpc_route_table" "dmz-rt" {
  folder_id = yandex_resourcemanager_folder.folder1.id
  network_id = yandex_vpc_network.vpc_name_1.id
  name = "dmz-rt"

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = "${cidrhost(var.subnet-a_vpc_1, 10)}"
  }
}

// Create static routes for app vpc
resource "yandex_vpc_route_table" "app-rt" {
  folder_id = yandex_resourcemanager_folder.folder2.id
  network_id = yandex_vpc_network.vpc_name_2.id
  name = "app-rt"

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = "${cidrhost(var.subnet-a_vpc_2, 10)}"
  }
}

// Create static routes for mgmt vpc
resource "yandex_vpc_route_table" "mgmt-rt" {
  folder_id = yandex_resourcemanager_folder.folder4.id
  network_id = yandex_vpc_network.vpc_name_4.id
  name = "mgmt-rt"

  static_route {
    destination_prefix = var.subnet-a_vpc_1
    next_hop_address   = "${cidrhost(var.subnet-a_vpc_4, 10)}"
  }
  
  static_route {
    destination_prefix = var.subnet-b_vpc_1
    next_hop_address   = "${cidrhost(var.subnet-a_vpc_4, 10)}"
  }

  static_route {
    destination_prefix = var.subnet-a_vpc_2
    next_hop_address   = "${cidrhost(var.subnet-a_vpc_4, 10)}"
  }
  
  static_route {
    destination_prefix = var.subnet-b_vpc_2
    next_hop_address   = "${cidrhost(var.subnet-a_vpc_4, 10)}"
  }

  static_route {
    destination_prefix = var.subnet-a_vpc_3
    next_hop_address   = "${cidrhost(var.subnet-a_vpc_4, 10)}"
  }
  
  static_route {
    destination_prefix = var.subnet-b_vpc_3
    next_hop_address   = "${cidrhost(var.subnet-a_vpc_4, 10)}"
  }

  static_route {
    destination_prefix = var.subnet-a_vpc_5
    next_hop_address   = "${cidrhost(var.subnet-a_vpc_4, 10)}"
  }
  
  static_route {
    destination_prefix = var.subnet-b_vpc_5
    next_hop_address   = "${cidrhost(var.subnet-a_vpc_4, 10)}"
  }

  static_route {
    destination_prefix = var.subnet-a_vpc_6
    next_hop_address   = "${cidrhost(var.subnet-a_vpc_4, 10)}"
  }
  
  static_route {
    destination_prefix = var.subnet-b_vpc_6
    next_hop_address   = "${cidrhost(var.subnet-a_vpc_4, 10)}"
  }

  static_route {
    destination_prefix = var.subnet-a_vpc_7
    next_hop_address   = "${cidrhost(var.subnet-a_vpc_4, 10)}"
  }
  
  static_route {
    destination_prefix = var.subnet-b_vpc_7
    next_hop_address   = "${cidrhost(var.subnet-a_vpc_4, 10)}"
  }

  static_route {
    destination_prefix = var.subnet-a_vpc_8
    next_hop_address   = "${cidrhost(var.subnet-a_vpc_4, 10)}"
  }
  
  static_route {
    destination_prefix = var.subnet-b_vpc_8
    next_hop_address   = "${cidrhost(var.subnet-a_vpc_4, 10)}"
  }
}

// Create static routes for database vpc
resource "yandex_vpc_route_table" "database-rt" {
  folder_id = yandex_resourcemanager_folder.folder5.id
  network_id = yandex_vpc_network.vpc_name_5.id
  name = "database-rt"

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = "${cidrhost(var.subnet-a_vpc_5, 10)}"
  }
}


// Create networks-------------------

// --VPC 1-- DMZ
resource "yandex_vpc_network" "vpc_name_1" {
  name = var.vpc_name_1
  folder_id = yandex_resourcemanager_folder.folder1.id
}
resource "yandex_vpc_subnet" "subnet-a_vpc_1" {
  folder_id = yandex_resourcemanager_folder.folder1.id
  name           = var.subnet-a_vpc_1
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.vpc_name_1.id
  v4_cidr_blocks = [var.subnet-a_vpc_1]
  route_table_id = yandex_vpc_route_table.dmz-rt.id
}
resource "yandex_vpc_subnet" "subnet-b_vpc_1" {
  folder_id = yandex_resourcemanager_folder.folder1.id
  name           = var.subnet-b_vpc_1
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.vpc_name_1.id
  v4_cidr_blocks = [var.subnet-b_vpc_1]
  route_table_id = yandex_vpc_route_table.dmz-rt.id
}

// --VPC 2-- app
resource "yandex_vpc_network" "vpc_name_2" {
  name = var.vpc_name_2
  folder_id = yandex_resourcemanager_folder.folder2.id
}
resource "yandex_vpc_subnet" "subnet-a_vpc_2" {
  folder_id = yandex_resourcemanager_folder.folder2.id
  name           = var.subnet-a_vpc_2
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.vpc_name_2.id
  v4_cidr_blocks = [var.subnet-a_vpc_2]
  route_table_id = yandex_vpc_route_table.app-rt.id
}
resource "yandex_vpc_subnet" "subnet-b_vpc_2" {
  folder_id = yandex_resourcemanager_folder.folder2.id
  name           = var.subnet-b_vpc_2
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.vpc_name_2.id
  v4_cidr_blocks = [var.subnet-b_vpc_2]
  route_table_id = yandex_vpc_route_table.app-rt.id
}

// --VPC 3-- public
resource "yandex_vpc_network" "vpc_name_3" {
  name = var.vpc_name_3
  folder_id = yandex_resourcemanager_folder.folder3.id
}
resource "yandex_vpc_subnet" "subnet-a_vpc_3" {
  folder_id = yandex_resourcemanager_folder.folder3.id
  name           = var.subnet-a_vpc_3
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.vpc_name_3.id
  v4_cidr_blocks = [var.subnet-a_vpc_3]
}
resource "yandex_vpc_subnet" "subnet-b_vpc_3" {
  folder_id = yandex_resourcemanager_folder.folder3.id
  name           = var.subnet-b_vpc_3
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.vpc_name_3.id
  v4_cidr_blocks = [var.subnet-b_vpc_3]
}

// --VPC 4-- management
resource "yandex_vpc_network" "vpc_name_4" {
  name = var.vpc_name_4
  folder_id = yandex_resourcemanager_folder.folder4.id
}
resource "yandex_vpc_subnet" "subnet-a_vpc_4" {
  folder_id = yandex_resourcemanager_folder.folder4.id
  name           = var.subnet-a_vpc_4
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.vpc_name_4.id
  v4_cidr_blocks = [var.subnet-a_vpc_4]
  route_table_id = yandex_vpc_route_table.mgmt-rt.id
}
resource "yandex_vpc_subnet" "subnet-b_vpc_4" {
  folder_id = yandex_resourcemanager_folder.folder4.id
  name           = var.subnet-b_vpc_4
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.vpc_name_4.id
  v4_cidr_blocks = [var.subnet-b_vpc_4]
  route_table_id = yandex_vpc_route_table.mgmt-rt.id
}

// --VPC-5-- database
resource "yandex_vpc_network" "vpc_name_5" {
  name = var.vpc_name_5
  folder_id = yandex_resourcemanager_folder.folder5.id
}
resource "yandex_vpc_subnet" "subnet-a_vpc_5" {
  folder_id = yandex_resourcemanager_folder.folder5.id
  name           = var.subnet-a_vpc_5
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.vpc_name_5.id
  v4_cidr_blocks = [var.subnet-a_vpc_5]
  route_table_id = yandex_vpc_route_table.database-rt.id
}
resource "yandex_vpc_subnet" "subnet-b_vpc_5" {
  folder_id = yandex_resourcemanager_folder.folder5.id
  name           = var.subnet-b_vpc_5
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.vpc_name_5.id
  v4_cidr_blocks = [var.subnet-b_vpc_5]
  route_table_id = yandex_vpc_route_table.database-rt.id
}

// VPC-6
resource "yandex_vpc_network" "vpc_name_6" {
  name = var.vpc_name_6
  folder_id = yandex_resourcemanager_folder.folder6.id
}
resource "yandex_vpc_subnet" "subnet-a_vpc_6" {
  folder_id = yandex_resourcemanager_folder.folder6.id
  name           = var.subnet-a_vpc_6
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.vpc_name_6.id
  v4_cidr_blocks = [var.subnet-a_vpc_6]
}
resource "yandex_vpc_subnet" "subnet-b_vpc_6" {
  folder_id = yandex_resourcemanager_folder.folder6.id
  name           = var.subnet-b_vpc_6
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.vpc_name_6.id
  v4_cidr_blocks = [var.subnet-b_vpc_6]
}

// VPC-7
resource "yandex_vpc_network" "vpc_name_7" {
  name = var.vpc_name_7
  folder_id = yandex_resourcemanager_folder.folder7.id
}
resource "yandex_vpc_subnet" "subnet-a_vpc_7" {
  folder_id = yandex_resourcemanager_folder.folder7.id
  name           = var.subnet-a_vpc_7
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.vpc_name_7.id
  v4_cidr_blocks = [var.subnet-a_vpc_7]
}
resource "yandex_vpc_subnet" "subnet-b_vpc_7" {
  folder_id = yandex_resourcemanager_folder.folder7.id
  name           = var.subnet-b_vpc_7
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.vpc_name_7.id
  v4_cidr_blocks = [var.subnet-b_vpc_7]
}

// VPC-8
resource "yandex_vpc_network" "vpc_name_8" {
  name = var.vpc_name_8
  folder_id = yandex_resourcemanager_folder.folder8.id
}
resource "yandex_vpc_subnet" "subnet-a_vpc_8" {
  folder_id = yandex_resourcemanager_folder.folder8.id
  name           = var.subnet-a_vpc_8
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.vpc_name_8.id
  v4_cidr_blocks = [var.subnet-a_vpc_8]
}
resource "yandex_vpc_subnet" "subnet-b_vpc_8" {
  folder_id = yandex_resourcemanager_folder.folder8.id
  name           = var.subnet-b_vpc_8
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.vpc_name_8.id
  v4_cidr_blocks = [var.subnet-b_vpc_8]
}


// Create static public IP-------------------

// Static public IP for fw ALB
resource "yandex_vpc_address" "public-ip-fw-alb" {
  name = "public-ip-fw-alb"
  folder_id = yandex_resourcemanager_folder.folder3.id
  external_ipv4_address {
    zone_id = "ru-central1-a"
  }
}

// Static public IP for Jump VM
resource "yandex_vpc_address" "public-ip-jump-vm" {
  name = "public-ip-jump-vm"
  folder_id = yandex_resourcemanager_folder.folder4.id
  external_ipv4_address {
    zone_id = "ru-central1-a"
  }
}


