resource "azurerm_resource_group" "service" {
  name     = "${var.name_prefix}-rg"
  location = var.location
}

resource "azurerm_storage_account" "functions" {
  name                            = "${replace(var.name_prefix, "-", "")}st"
  resource_group_name             = azurerm_resource_group.service.name
  location                        = azurerm_resource_group.service.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_container" "deployments" {
  name                  = "function-deployments"
  storage_account_id    = azurerm_storage_account.functions.id
  container_access_type = "private"
}

resource "azurerm_service_plan" "functions" {
  name                = "${var.name_prefix}-plan"
  resource_group_name = azurerm_resource_group.service.name
  location            = azurerm_resource_group.service.location
  os_type             = "Linux"
  sku_name            = "FC1"
}

resource "azurerm_function_app_flex_consumption" "service" {
  name                = "${var.name_prefix}-func"
  resource_group_name = azurerm_resource_group.service.name
  location            = azurerm_resource_group.service.location
  service_plan_id     = azurerm_service_plan.functions.id
  https_only          = true

  storage_container_type      = "blobContainer"
  storage_container_endpoint  = "${azurerm_storage_account.functions.primary_blob_endpoint}${azurerm_storage_container.deployments.name}"
  storage_authentication_type = "StorageAccountConnectionString"
  storage_access_key          = azurerm_storage_account.functions.primary_access_key

  runtime_name           = "node"
  runtime_version        = "22"
  maximum_instance_count = 40
  instance_memory_in_mb  = 2048

  app_settings = {
    AzureWebJobsStorage = azurerm_storage_account.functions.primary_connection_string
  }

  site_config {
    minimum_tls_version = "1.2"

    dynamic "cors" {
      for_each = length(var.cors_allowed_origins) > 0 ? [var.cors_allowed_origins] : []

      content {
        allowed_origins = cors.value
      }
    }
  }
}
