mock_provider "helm" {}
mock_provider "kubernetes" {}

variables {
  alertmanager_webhook_secret_ref = {
    name = "alertmanager-webhook"
    key  = "url"
  }
  grafana_admin_password_secret_ref = {
    name = "grafana-admin"
    key  = "password"
  }
}

run "defaults_render_rules_and_dashboards" {
  command = plan

  module {
    source = "./modules/monitoring-stack"
  }

  assert {
    condition     = length(yamldecode(helm_release.monitoring_stack.values[0]).additionalPrometheusRulesMap.node-pod-health.groups) == 2
    error_message = "expected both rule groups (node-health, pod-health) in additionalPrometheusRulesMap"
  }

  assert {
    condition     = kubernetes_config_map_v1.dashboards["node-health"].metadata[0].labels["grafana_dashboard"] == "1"
    error_message = "node-health dashboard ConfigMap must carry the grafana_dashboard sidecar label"
  }

  assert {
    condition     = kubernetes_config_map_v1.dashboards["pod-health"].metadata[0].labels["grafana_dashboard"] == "1"
    error_message = "pod-health dashboard ConfigMap must carry the grafana_dashboard sidecar label"
  }

  assert {
    condition     = yamldecode(helm_release.monitoring_stack.values[0]).grafana.admin.existingSecret == "grafana-admin"
    error_message = "grafana admin password must come from the existing secret reference, not a plaintext value"
  }
}

run "feature_flags_propagate" {
  command = plan

  module {
    source = "./modules/monitoring-stack"
  }

  variables {
    enable_alertmanager = false
    enable_grafana      = false
  }

  assert {
    condition     = yamldecode(helm_release.monitoring_stack.values[0]).alertmanager.enabled == false
    error_message = "enable_alertmanager = false must disable alertmanager in the chart values"
  }

  assert {
    condition     = yamldecode(helm_release.monitoring_stack.values[0]).grafana.enabled == false
    error_message = "enable_grafana = false must disable grafana in the chart values"
  }
}

run "custom_retention_and_storage_apply" {
  command = plan

  module {
    source = "./modules/monitoring-stack"
  }

  variables {
    retention    = "7d"
    storage_size = "50Gi"
  }

  assert {
    condition     = yamldecode(helm_release.monitoring_stack.values[0]).prometheus.prometheusSpec.retention == "7d"
    error_message = "retention variable must propagate to prometheusSpec.retention"
  }

  assert {
    condition     = yamldecode(helm_release.monitoring_stack.values[0]).prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage == "50Gi"
    error_message = "storage_size variable must propagate to the PVC request size"
  }
}

run "rejects_invalid_namespace" {
  command = plan

  module {
    source = "./modules/monitoring-stack"
  }

  variables {
    namespace = "Not_Valid"
  }

  expect_failures = [var.namespace]
}

run "rejects_invalid_chart_version" {
  command = plan

  module {
    source = "./modules/monitoring-stack"
  }

  variables {
    chart_version = "latest"
  }

  expect_failures = [var.chart_version]
}

run "rejects_invalid_retention" {
  command = plan

  module {
    source = "./modules/monitoring-stack"
  }

  variables {
    retention = "15days"
  }

  expect_failures = [var.retention]
}

run "rejects_invalid_storage_size" {
  command = plan

  module {
    source = "./modules/monitoring-stack"
  }

  variables {
    storage_size = "20"
  }

  expect_failures = [var.storage_size]
}

run "rejects_empty_alertmanager_secret_key" {
  command = plan

  module {
    source = "./modules/monitoring-stack"
  }

  variables {
    alertmanager_webhook_secret_ref = {
      name = "alertmanager-webhook"
      key  = ""
    }
  }

  expect_failures = [var.alertmanager_webhook_secret_ref]
}

run "rejects_empty_grafana_secret_name" {
  command = plan

  module {
    source = "./modules/monitoring-stack"
  }

  variables {
    grafana_admin_password_secret_ref = {
      name = "  "
      key  = "password"
    }
  }

  expect_failures = [var.grafana_admin_password_secret_ref]
}
