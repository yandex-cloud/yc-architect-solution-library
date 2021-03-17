resource "yandex_mdb_mysql_cluster" "bu_1_db" {
  name        = "bu-1-db1"
  environment = "PRESTABLE"
  network_id  = yandex_vpc_network.bu_1_net.id
  version     = "8.0"

  resources {
    resource_preset_id = "s2.micro"
    disk_type_id       = "network-ssd"
    disk_size          = 40
  }

  database {
    name = "db_name"
  }

  user {
    name     = "user_name"
    password = "your_password"
    permission {
      database_name = "db_name"
      roles         = ["ALL"]
    }
  }

  host {
    zone      = "ru-central1-a"
    subnet_id = yandex_vpc_subnet.bu_1_subnet.0.id
  }
}


resource "yandex_mdb_mysql_cluster" "bu_2_db" {
  name        = "bu-2-db1"
  environment = "PRESTABLE"
  network_id  = yandex_vpc_network.bu_2_net.id
  version     = "8.0"

  resources {
    resource_preset_id = "s2.micro"
    disk_type_id       = "network-ssd"
    disk_size          = 40
  }

  database {
    name = "db_name"
  }

  user {
    name     = "user_name"
    password = "your_password"
    permission {
      database_name = "db_name"
      roles         = ["ALL"]
    }
  }

  host {
    zone      = "ru-central1-a"
    subnet_id = yandex_vpc_subnet.bu_2_subnet.0.id
  }

  host {
    zone      = "ru-central1-b"
    subnet_id = yandex_vpc_subnet.bu_2_subnet.1.id
    assign_public_ip = true
  }
  
}
