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
variable "tenant_id" {
  description = "**********"
  type        = string
}

variable "subscription_id" {
  description = "************"
  type        = string
}

variable "client_id" {
  description = "******"
  type        = string
}

variable "client_secret" {
  description = "*********"
  type        = string
  sensitive   = true
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