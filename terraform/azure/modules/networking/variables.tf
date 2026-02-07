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

variable "subnet_names" {
  description = "Names of existing subnets. Used when not bootstrapping."
  type        = list(string)
}

variable "subnet_cidrs" {
  description = "CIDR blocks for subnets when bootstrapping."
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT Gateway when bootstrapping."
  type        = bool
}
