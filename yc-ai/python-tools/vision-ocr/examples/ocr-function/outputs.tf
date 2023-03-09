output "bucket" {
  value   = "${yandex_storage_bucket.bucket.id}"
}

output "function" {
  value = "${yandex_function.main.name}"
}