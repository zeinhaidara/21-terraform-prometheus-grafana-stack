# Generic kubeconfig-based provider config. For a specific cloud, replace this block with the
# one from the README's provider table - the module itself does not change either way.
provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes = {
    config_path = var.kubeconfig_path
  }
}
