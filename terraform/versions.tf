terraform {
  required_version = ">= 1.7, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.64"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}
