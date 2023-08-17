resource "random_string" "bucket_suffix" {
  length  = 10
  upper   = false
  lower   = true
  numeric  = true
  special = false
}

// create Object Storage bucket for testing purpose
resource "yandex_storage_bucket" "s3_test_bucket" {
  bucket     = "s3-test-bucket-${random_string.bucket_suffix.result}"
  access_key = yandex_iam_service_account_static_access_key.s3_test_bucket_sa_keys.access_key
  secret_key = yandex_iam_service_account_static_access_key.s3_test_bucket_sa_keys.secret_key
  depends_on = [yandex_resourcemanager_folder_iam_member.s3_test_bucket_sa_roles]
}

resource "yandex_storage_object" "s3_test_file" {
  bucket     = yandex_storage_bucket.s3_test_bucket.id
  access_key = yandex_iam_service_account_static_access_key.s3_test_bucket_sa_keys.access_key
  secret_key = yandex_iam_service_account_static_access_key.s3_test_bucket_sa_keys.secret_key
  key        = "s3_test_file.txt"
  content    = "Object Storage test file was successfully downloaded\n"
}