# Rules go through the chart's additionalPrometheusRulesMap values key, not a kubernetes_manifest
# PrometheusRule resource - a manifest resource needs a live API server to plan against, and this
# module has to plan cleanly with mock providers and no cluster.
locals {
  rules_content = yamldecode(file("${path.module}/rules/node-pod-health.rules.yml"))

  dashboard_files = fileset("${path.module}/dashboards", "*.json")

  values = {
    additionalPrometheusRulesMap = {
      node-pod-health = local.rules_content
    }

    prometheus = {
      prometheusSpec = {
        retention = var.retention
        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              accessModes = ["ReadWriteOnce"]
              resources = {
                requests = {
                  storage = var.storage_size
                }
              }
            }
          }
        }
      }
    }

    alertmanager = {
      enabled = var.enable_alertmanager
      alertmanagerSpec = {
        # Mounts the existing secret into the pod; the receiver below reads the URL from the
        # mounted file so the webhook URL itself never passes through a Terraform value.
        secrets = [var.alertmanager_webhook_secret_ref.name]
      }
      config = {
        route = {
          receiver = "webhook"
        }
        receivers = [
          {
            name = "webhook"
            webhook_configs = [
              {
                url_file = "/etc/alertmanager/secrets/${var.alertmanager_webhook_secret_ref.name}/${var.alertmanager_webhook_secret_ref.key}"
              }
            ]
          }
        ]
      }
    }

    grafana = {
      enabled = var.enable_grafana
      admin = {
        existingSecret = var.grafana_admin_password_secret_ref.name
        passwordKey    = var.grafana_admin_password_secret_ref.key
      }
      sidecar = {
        dashboards = {
          enabled = true
          label   = "grafana_dashboard"
        }
      }
    }
  }
}

resource "helm_release" "monitoring_stack" {
  name       = "monitoring-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.chart_version
  namespace  = var.namespace

  create_namespace = true

  values = [yamlencode(local.values)]
}

# One ConfigMap per dashboard file, labeled for the chart's built-in Grafana sidecar to pick up -
# this is how dashboards ship without a kubernetes_manifest resource.
resource "kubernetes_config_map_v1" "dashboards" {
  for_each = { for f in local.dashboard_files : trimsuffix(f, ".json") => f }

  metadata {
    name      = "dashboard-${each.key}"
    namespace = var.namespace
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "${each.key}.json" = file("${path.module}/dashboards/${each.value}")
  }

  depends_on = [helm_release.monitoring_stack]
}
