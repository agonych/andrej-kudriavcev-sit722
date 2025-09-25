variable "prefix" {
  description = "Prefix for all staging resource names"
  type        = string
  default     = "sit722akstaging"
}

variable "prefixprod" {
  description = "Prefix of the prod resources (shared ACR/RG)"
  type        = string
  default     = "sit722akprod"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "australiaeast"
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS cluster"
  type        = string
  default     = "1.31.7"
}
