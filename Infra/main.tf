data "azurerm_client_config" "current" {}

# resource "random_string" "suffix" {
#   length  = 5
#   special = false
#   upper   = false
# }

# -----------------------------
# RESOURCE GROUP
# -----------------------------
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

# -----------------------------
# STORAGE (ADLS GEN2)
# -----------------------------
resource "azurerm_storage_account" "stg" {
  name                     = "stgdataengaccountctlus"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true

  identity {
    type = "SystemAssigned"
  }
}
# -----------------------------
# DATABRICKS ACCESS CONNECTOR
# -----------------------------
resource "azurerm_databricks_access_connector" "adb_connector" {
  name                = "adb-connector-ctlus-prod"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  identity {
    type = "SystemAssigned"
  }
}

# -----------------------------
# DATABRICKS WORKSPACE
# -----------------------------
resource "azurerm_databricks_workspace" "adb" {
  name                        = "adb-dataeng-ws-ctlus-prod"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  sku                         = "premium"
  managed_resource_group_name = "rg-adb-managed-ctlus-prod"
}

# -----------------------------
# RBAC (DATABRICKS → STORAGE)
# -----------------------------
resource "azurerm_role_assignment" "adb_storage" {
  scope                = azurerm_storage_account.stg.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.adb_connector.identity[0].principal_id
}
# -----------------------------
# DATA FACTORY (FIXED UNIQUE)
# -----------------------------
resource "azurerm_data_factory" "adf" {
  name                = "adf-dataeng-ctlus-prod"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  identity {
    type = "SystemAssigned"
  }
}

# -----------------------------
# KEY VAULT
# -----------------------------
resource "azurerm_key_vault" "akv" {
  name                        = "akvdataeng-ctlus-prod"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"

  purge_protection_enabled   = false
  soft_delete_retention_days = 7

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = ["Get", "List", "Set", "Delete"]
  }
}

# -----------------------------
# SQL SERVER
# -----------------------------
resource "azurerm_mssql_server" "sql" {
  name                         = "sqldataeng-ctlus-prod"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_user
  administrator_login_password = var.sql_admin_password
}

# -----------------------------
# SQL DATABASE (LOW COST)
# -----------------------------
resource "azurerm_mssql_database" "sqldb" {
  name        = "sqldb-prod"
  server_id   = azurerm_mssql_server.sql.id
  sku_name    = "Basic"
  max_size_gb = 2
}

# -----------------------------
# SQL FIREWALL (ALLOW ALL)
# -----------------------------
resource "azurerm_mssql_firewall_rule" "allow_all" {
  name             = "AllowAll"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}

# -----------------------------
# RBAC (ADF ACCESS)
# -----------------------------
resource "azurerm_role_assignment" "adf_storage" {
  scope                = azurerm_storage_account.stg.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_factory.adf.identity[0].principal_id
}

resource "azurerm_role_assignment" "adf_rg" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_data_factory.adf.identity[0].principal_id
}

# -----------------------------
# OUTPUTS
# -----------------------------
output "subscription_id" {
  value = data.azurerm_client_config.current.subscription_id
}

output "data_factory_name" {
  value = azurerm_data_factory.adf.name
}