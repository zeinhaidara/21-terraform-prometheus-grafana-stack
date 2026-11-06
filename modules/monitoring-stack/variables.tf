variable "namespace" {
  description = "Namespace the stack is installed into. Created if it does not exist."
  type        = string
  default     = "monitoring"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace)) && length(var.namespace) <= 63
    error_message = "namespace must be a valid Kubernetes name: lowercase alphanumeric and hyphens, 1-63 characters."
  }
}

variable "chart_version" {
  description = "kube-prometheus-stack chart version to install. Pinned; see README for the version checked against the chart repo."
  type        = string
  default     = "92.21.2"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.chart_version))
    error_message = "chart_version must be a semver string, e.g. 92.21.2."
  }
}

variable "retention" {
  description = "How long Prometheus retains metrics, e.g. 15d, 12h."
  type        = string
  default     = "15d"

  validation {
    condition     = can(regex("^[0-9]+[smhdwy]$", var.retention))
    error_message = "retention must be a number followed by one of s, m, h, d, w, y, e.g. 15d."
  }
}

variable "storage_size" {
  description = "Size of the Prometheus persistent volume claim, e.g. 20Gi."
  type        = string
  default     = "20Gi"

  validation {
    condition     = can(regex("^[0-9]+(\\.[0-9]+)?(Ei|Pi|Ti|Gi|Mi|Ki)$", var.storage_size))
    error_message = "storage_size must be a Kubernetes quantity with a binary suffix, e.g. 20Gi."
  }
}

variable "enable_alertmanager" {
  description = "Whether to install Alertmanager as part of the stack."
  type        = bool
  default     = true
}

variable "enable_grafana" {
  description = "Whether to install Grafana as part of the stack."
  type        = bool
  default     = true
}

variable "alertmanager_webhook_secret_ref" {
  description = "Name and key of an existing Kubernetes Secret holding the Alertmanager webhook receiver URL. The URL itself is never a Terraform value - only this reference is."
  type = object({
    name = string
    key  = string
  })

  validation {
    condition     = length(trimspace(var.alertmanager_webhook_secret_ref.name)) > 0 && length(trimspace(var.alertmanager_webhook_secret_ref.key)) > 0
    error_message = "alertmanager_webhook_secret_ref.name and .key must both be non-empty."
  }
}

variable "grafana_admin_password_secret_ref" {
  description = "Name and key of an existing Kubernetes Secret holding the Grafana admin password. The password itself is never a Terraform value - only this reference is."
  type = object({
    name = string
    key  = string
  })

  validation {
    condition     = length(trimspace(var.grafana_admin_password_secret_ref.name)) > 0 && length(trimspace(var.grafana_admin_password_secret_ref.key)) > 0
    error_message = "grafana_admin_password_secret_ref.name and .key must both be non-empty."
  }
}
