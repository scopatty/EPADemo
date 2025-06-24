variable "location" {
  description = "Azure region location"
  type        = string
  default     = "UK South"
}

variable "resource_group_name" {
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