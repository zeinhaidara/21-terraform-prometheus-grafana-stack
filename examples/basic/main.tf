module "monitoring_stack" {
  source = "../../modules/monitoring-stack"

  namespace     = "monitoring"
  chart_version = "92.21.2"
  retention     = "15d"
  storage_size  = "20Gi"

  enable_alertmanager = true
  enable_grafana      = true

  # Both of these must already exist in the target namespace - see the README for how to
  # create them. Neither the webhook URL nor the password ever becomes a Terraform value.
  alertmanager_webhook_secret_ref = {
    name = "alertmanager-webhook"
    key  = "url"
  }

  grafana_admin_password_secret_ref = {
    name = "grafana-admin"
    key  = "password"
  }

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }
}
