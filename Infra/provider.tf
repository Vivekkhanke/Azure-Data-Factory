terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.117"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.35"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "<subscription-id>"
}

provider "databricks" {
  host = azurerm_databricks_workspace.databricks.workspace_url
}
