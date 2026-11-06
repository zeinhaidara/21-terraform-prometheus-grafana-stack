output "release_name" {
  description = "Name of the Helm release."
  value       = helm_release.monitoring_stack.name
}

output "release_namespace" {
  description = "Namespace the stack was installed into."
  value       = helm_release.monitoring_stack.namespace
}

output "dashboard_config_map_names" {
  description = "Names of the ConfigMaps created for Grafana dashboards."
  value       = [for cm in kubernetes_config_map_v1.dashboards : cm.metadata[0].name]
}
