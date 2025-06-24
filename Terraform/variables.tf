variable "location" {
  description = "Azure region location"
  type        = string
  default     = "UK South"
}

variable "application_resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "rg-uks-webapps"
}

variable "environment" {
  description = "The environment for the deployment (e.g., 'dev', 'prod')"
  type        = string
  default     = "dev" 
}

variable "connections_resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "rg-uks-connections"
}