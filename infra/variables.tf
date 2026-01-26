variable "project_name" {
  type        = string
  description = "Base name for Azure resources."
  default     = "project-hub"
}

variable "location" {
  type        = string
  description = "Azure region."
  default     = "eastus"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name."
  default     = "rg-project-hub"
}

variable "aks_node_count" {
  type        = number
  description = "AKS default node count."
  default     = 2
}

variable "aks_vm_size" {
  type        = string
  description = "AKS node VM size."
  default     = "Standard_DS2_v2"
}

variable "security_service_identifier_uri" {
  type        = string
  description = "Identifier URI for security-service API."
  default     = "api://security-service"
}

variable "project_hub_identifier_uri" {
  type        = string
  description = "Identifier URI for project-hub API."
  default     = "api://project-hub"
}

variable "spa_redirect_uris" {
  type        = list(string)
  description = "Redirect URIs for the Angular SPA."
  default     = ["http://localhost:4200/"]
}
