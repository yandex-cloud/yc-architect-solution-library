output "access_key" {
  value = yandex_iam_service_account_static_access_key.sa-static-key.access_key

  description = "Access key for sa-backup-funtions service account"
}
output "secret_key" {
  value       = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  sensitive   = true
  description = "Secret key for sa-backup-funtions service account"
}


