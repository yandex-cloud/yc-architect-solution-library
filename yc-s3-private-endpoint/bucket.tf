resource "random_string" "bucket_suffix" {
  length  = 10
  upper   = false
  lower   = true
  numeric  = true
  special = false
}

// create Object Storage bucket for testing purpose
resource "yandex_storage_bucket" "s3_bucket" {
  bucket     = "s3-bucket-${random_string.bucket_suffix.result}"
  access_key = yandex_iam_service_account_static_access_key.s3_bucket_sa_keys.access_key
  secret_key = yandex_iam_service_account_static_access_key.s3_bucket_sa_keys.secret_key
  depends_on = [yandex_resourcemanager_folder_iam_member.s3_bucket_sa_roles]
  policy = !var.bucket_private_access ? null : <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Allow access to bucket only from NAT-instances public IP-address",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::s3-bucket-${random_string.bucket_suffix.result}/*",
        "arn:aws:s3:::s3-bucket-${random_string.bucket_suffix.result}"
      ],
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": [
            "${join("\",\"", yandex_vpc_address.public_ip_list.*.external_ipv4_address.0.address)}${var.mgmt_ip != null ? "\",\"${var.mgmt_ip}" : "" }"
          ]
        }
      } 
    }
    ${var.bucket_console_access ? <<EOT
    ,
    {
      "Sid": "Allow access to bucket from UI console",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "*",
      "Resource": [
        "arn:aws:s3:::s3-bucket-${random_string.bucket_suffix.result}/*",
        "arn:aws:s3:::s3-bucket-${random_string.bucket_suffix.result}"
      ],
      "Condition": {
        "StringLike": {
          "aws:referer": "https://console.cloud.yandex.*/folders/*/storage/buckets/s3-bucket-${random_string.bucket_suffix.result}*"
        }
      }
    }
    EOT
    : ""
    }
  ]
}
POLICY
}

resource "yandex_storage_object" "s3_test_file" {
  bucket     = yandex_storage_bucket.s3_bucket.id
  access_key = yandex_iam_service_account_static_access_key.s3_bucket_sa_keys.access_key
  secret_key = yandex_iam_service_account_static_access_key.s3_bucket_sa_keys.secret_key
  key        = "s3_test_file.txt"
  content    = "Object Storage test file was successfully downloaded\n"
}