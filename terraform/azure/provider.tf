terraform {
  required_providers {
    random = {
      source = "hashicorp/random"
    }

    cloudinit = {
      source = "hashicorp/cloudinit"
    }

    azurerm = {
      source = "hashicorp/azurerm"
    }

    tls = {
      source = "hashicorp/tls"
    }
  }
}

provider "azurerm" {
  features {}
}
