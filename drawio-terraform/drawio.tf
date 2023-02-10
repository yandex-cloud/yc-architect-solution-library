# ======================
# DrawIO diagram builder
# ======================

locals {
  dwdata = <<-EOT
    cloud_id=\"${var.cloud_id}\" 
    folder_id=\"${var.folder_id}\" 
    vm_name=\"${upper(var.vm_name)}\" 
    subnet_name=\"${data.yandex_vpc_subnet.subnet.name}\" 
    vm_priv_ip=\"${yandex_compute_instance.vm.network_interface[0].ip_address}\" 
    vm_pub_ip=\"${yandex_compute_instance.vm.network_interface[0].nat_ip_address}\" 
  EOT
  draw_data = replace(replace( templatefile(var.draw_template_name, { TF_DRAW_DATA = local.dwdata} ), "\n",""), "\\","")
}

resource "local_file" "diagram" {
  content = local.draw_data
  filename = var.draw_name
}
