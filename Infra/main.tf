# Get current Azure client config (used for RBAC role assignments)
data "azurerm_client_config" "current" {}

# Get current public IP for firewall rules
data "http" "current_ip" {
  url = "https://api.ipify.org"
}

# -------------------------------
# Resource Group
# -------------------------------
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# -------------------------------
# Storage Account
# -------------------------------
resource "azurerm_storage_account" "storage" {
  name                     = "dataengeus2dev"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true

  allow_nested_items_to_be_public = false
}

# -------------------------------
# Azure Data Factory
# -------------------------------
resource "azurerm_data_factory" "adf" {
  name                = "adf-data-dev-eus2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  
  identity {
    type = "SystemAssigned"
  }
}

# -------------------------------
# Azure Key Vault (EUS2)
# -------------------------------
resource "azurerm_key_vault" "kv" {
  name                        = "kv-dataeng-dev-eus2"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false
  soft_delete_retention_days  = 7

  timeouts {
    create = "1h"
    delete = "1h"
  }

  # Grant the deploying principal full management permissions
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List", "Create", "Delete", "Encrypt", "Decrypt"
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete"
    ]
  }

  # Grant Data Factory (system-assigned) access to get/set secrets
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_data_factory.adf.identity[0].principal_id

    secret_permissions = [
      "Get", "List", "Set"
    ]
  }
}

# Store SQL admin password in Key Vault (optional convenience)
resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  value        = var.sql_admin_password
  key_vault_id = azurerm_key_vault.kv.id
}

# -------------------------------
# Azure Databricks
# -------------------------------
resource "azurerm_databricks_workspace" "databricks" {
  name                = "databricks-dataeng-dev-eus2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "premium"  # upgraded to Premium for RBAC & advanced features

  # Optional Premium-only features can be enabled here, for example:
  # customer_managed_key_enabled = true
  # enhanced_security_compliance {
  #   automatic_cluster_update_enabled = true
  #   enhanced_security_monitoring_enabled = true
  # }
}

# Grant the current principal Contributor role specifically at the Databricks Workspace scope
resource "azurerm_role_assignment" "databricks_contributor" {
  scope                = azurerm_databricks_workspace.databricks.id
  role_definition_name = "Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# -------------------------------
# RBAC Role Assignments
# -------------------------------
# Grant the current principal Contributor role at the Resource Group scope
resource "azurerm_role_assignment" "rg_contributor" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Grant Storage Blob Data Contributor at the Storage Account scope (for data plane operations)
resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Grant Contributor role at specific resource scopes for current principal
resource "azurerm_role_assignment" "storage_contributor" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "adf_contributor" {
  scope                = azurerm_data_factory.adf.id
  role_definition_name = "Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "sql_contributor" {
  scope                = azurerm_mssql_server.sql_server.id
  role_definition_name = "Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# -------------------------------
# Azure SQL Server
# -------------------------------
resource "azurerm_mssql_server" "sql_server" {
  name                         = "sql-dataeng-dev-eus2"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
}

# -------------------------------
# Azure SQL Database (CHEAPEST)
# -------------------------------
resource "azurerm_mssql_database" "sql_db" {
  name           = "sqldb-dataeng-dev-eus2"
  server_id     = azurerm_mssql_server.sql_server.id
  sku_name      = "Basic"
  max_size_gb   = 2

  zone_redundant = false
}
resource "azurerm_mssql_firewall_rule" "allow_azure" {
  name      = "AllowAzureServices"
  server_id = azurerm_mssql_server.sql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# -------------------------------
# Allow My Local IP (SQL Access)
# -------------------------------
resource "azurerm_mssql_firewall_rule" "allow_my_ip" {
  name             = "AllowMyLocalIP"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "103.174.141.76"
  end_ip_address   = "103.174.141.76"
}

# -------------------------------
# Allow Current Public IP (SQL Access)
# -------------------------------
resource "azurerm_mssql_firewall_rule" "allow_current_ip" {
  name             = "AllowCurrentIP"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = data.http.current_ip.response_body
  end_ip_address   = data.http.current_ip.response_body
}

# -------------------------------
# Cheapest Single Node Databricks Cluster
# -------------------------------
resource "databricks_cluster" "single_node_cluster" {
  cluster_name            = "adb-cluster-dev-eus2"
  spark_version           = "14.3.x-scala2.12"  # Latest LTS version
  node_type_id            = "Standard_D4s_v3"   # Available in EUS2
  autotermination_minutes = 10

  num_workers = 0
  data_security_mode = "SINGLE_USER"

  spark_conf = {
    "spark.master" = "local[*]"
  }

  custom_tags = {
    "ResourceClass" = "SingleNode"
  }

  depends_on = [
    azurerm_databricks_workspace.databricks
  ]
}

# -------------------------------
# Outputs - Verify HNS is enabled
# -------------------------------
output "storage_hns_enabled" {
  description = "Verify hierarchical namespace is enabled for ADLS Gen2"
  value       = azurerm_storage_account.storage.is_hns_enabled
}

output "storage_account_kind" {
  description = "Storage account kind (should be StorageV2 for ADLS Gen2)"
  value       = azurerm_storage_account.storage.account_kind
}

output "key_vault_id" {
  description = "ID of the Key Vault created for EUS2"
  value       = azurerm_key_vault.kv.id
}

output "key_vault_uri" {
  description = "Vault URI for secrets access"
  value       = azurerm_key_vault.kv.vault_uri
}
