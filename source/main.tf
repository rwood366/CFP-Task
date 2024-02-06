//Variables populated via Github Secrets within the pipeline. 
//Do not manually enter values.
variable "ARM_CLIENT_ID" {}
variable "ARM_CLIENT_SECRET" {}
variable "ARM_SUBSCRIPTION_ID" {}
variable "ARM_TENANT_ID" {}

provider "azurerm" {
  features {}
  client_id       = var.ARM_CLIENT_ID
  client_secret   = var.ARM_CLIENT_SECRET
  subscription_id = var.ARM_SUBSCRIPTION_ID
  tenant_id       = var.ARM_TENANT_ID
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.15"
    }
  }

//variables not supported in backend.
  backend "remote" {
    organization = "rwood366"
    workspaces {
      name = "AZ-CFP-Demo"
    }
  }
}