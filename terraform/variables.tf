variable "prefix" {
    description = "Prefix for all resource names"
    type        = string
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

variable "subscription_id" {
    description = "Azure Subscription ID"
    type        = string
}
variable "tenant_id" {
    description = "Azure Tenant ID"
    type        = string
}
variable "client_id" {
    description = "Azure Client ID"
    type        = string
}
variable "client_secret" {
    description = "Azure Client Secret"
    type        = string
    sensitive   = true
}
