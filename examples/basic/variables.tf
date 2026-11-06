variable "kubeconfig_path" {
  description = "Path to a kubeconfig file. Works the same regardless of which cloud built the cluster - see the README for the EKS/AKS/GKE provider table."
  type        = string
  default     = "~/.kube/config"
}
