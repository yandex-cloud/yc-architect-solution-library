// Create service account for NAT-instances Instange Group and assign required roles for it
resource "yandex_iam_service_account" "nat_ig_sa" {
  folder_id = var.folder_id
  name = "nat-ig-sa"
}

resource "yandex_resourcemanager_folder_iam_member" "nat_ig_sa_roles" {
  folder_id = var.folder_id
  role   = "editor"
  member = "serviceAccount:${yandex_iam_service_account.nat_ig_sa.id}"
}

// Create service account for Object Storage bucket and assign required roles for it
resource "yandex_iam_service_account" "s3_bucket_sa" {
  folder_id = var.folder_id
  name = "s3-bucket-sa"
}

resource "yandex_resourcemanager_folder_iam_member" "s3_bucket_sa_roles" {
  folder_id = var.folder_id
  role   = "storage.admin"
  member = "serviceAccount:${yandex_iam_service_account.s3_bucket_sa.id}"
}

// Create static access key for service account to access Object Storage bucket
resource "yandex_iam_service_account_static_access_key" "s3_bucket_sa_keys" {
  service_account_id = yandex_iam_service_account.s3_bucket_sa.id
}

// Create security group for NAT instances
resource "yandex_vpc_security_group" "nat_sg" {
  name        = "s3-nat-sg"
  description = "Security group for NAT instances"
  folder_id   = var.folder_id
  network_id  = var.vpc_id == null ? yandex_vpc_network.vpc[0].id : var.vpc_id

  ingress {
    protocol            = "TCP"
    description         = "NLB healthcheck"
    port                = 443
    predefined_target   = "loadbalancer_healthchecks"
  }

  ingress {
    protocol            = "TCP"
    description         = "https requests to Object Storage from trusted cloud internal networks"
    port                = 443
    v4_cidr_blocks      = var.trusted_cloud_nets
  }

  egress {
    protocol       = "ANY"
    description    = "outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
