output "route-switcher_nlb" {
  description = "Internal NLB for checking status of routers"
  value  = yandex_lb_network_load_balancer.route_switcher_lb.name
}

output "route-switcher_bucket" {
  description = "Bucket for storing route-switcher module configuration"
  value        = yandex_storage_bucket.route_switcher_bucket.bucket
}

output "route-switcher_function" {
  description = "Route-switcher cloud function"
  value  = yandex_function.route-switcher.name
}
