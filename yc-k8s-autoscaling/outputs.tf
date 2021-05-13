output "network_id" {
  description = "The ID of the VPC"
  value       = yandex_vpc_network.this.id
}

output "subnet_ids" {
  value = [for subnet in yandex_vpc_subnet.this : subnet.id]
}

output "subnets" {
  value = { for v in yandex_vpc_subnet.this : v.zone => {
    "id"   = v.id,
    "name" = v.name,
    "zone" = v.zone
    }
  }
}
output "cluster_id" {
  value       = yandex_kubernetes_cluster.regional_cluster.id
  description = "cluster_id"
}
output "external_v4_endpoint" {
  value       = yandex_kubernetes_cluster.regional_cluster.master[0].external_v4_endpoint
  description = "cluster external_v4_endpoint"
}
