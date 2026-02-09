variable "prefix" {
  description = "Prefix for all Azure resources created by this module."
  type        = string
}

variable "location" {
  description = "Azure region to deploy to."
  type        = string
}

variable "resource_group" {
  description = "Resource group name."
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to all resources created by this module."
  type        = map(string)
}

variable "bootstrap_networking" {
  description = "Whether to bootstrap new networking resources."
  type        = bool
}

variable "vnet_name" {
  description = "Name of existing VNet. Used when not bootstrapping."
  type        = string
}

variable "vnet_cidr" {
  description = "CIDR block for the VNet when bootstrapping."
  type        = string
}

variable "subnet_name" {
  description = "Name of existing subnet. Used when not bootstrapping."
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR block for subnet when bootstrapping."
  type        = string
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT Gateway when bootstrapping."
  type        = bool
}
