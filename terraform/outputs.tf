output "resource_group_name" {
  description = "Resource group containing the service resources."
  value       = azurerm_resource_group.service.name
}

output "function_app_name" {
  description = "Function App name to pass to func azure functionapp publish."
  value       = azurerm_function_app_flex_consumption.service.name
}

output "products_url" {
  description = "Public HTTPS endpoint for GET, POST and PUT product requests."
  value       = "https://${azurerm_function_app_flex_consumption.service.default_hostname}/api/products"
}
