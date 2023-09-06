locals {
  kms_name        = lookup(var.kms_key, "name", "k8s-kms-key")
  kms_key_with_id = "${local.kms_name}${local.unique_id}"
}

resource "yandex_kms_symmetric_key" "kms_key" {
  count             = var.create_kms ? 1 : 0
  folder_id         = local.folder_id
  name              = local.kms_key_with_id
  description       = lookup(var.kms_key, "description", "K8S KMS symetric key")
  default_algorithm = lookup(var.kms_key, "default_algorithm", "AES_256")
  rotation_period   = lookup(var.kms_key, "rotation_period", "8760h")
}

resource "yandex_kms_symmetric_key_iam_binding" "encrypter_decrypter" {
  count            = var.create_kms ? 1 : 0
  symmetric_key_id = yandex_kms_symmetric_key.kms_key[count.index].id
  role             = "kms.keys.encrypterDecrypter"
  members = [
    "serviceAccount:${yandex_iam_service_account.master.id}",
  ]
}
