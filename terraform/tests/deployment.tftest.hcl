mock_provider "azurerm" {}

variables {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  location        = "uksouth"
  name_prefix     = "shopping-lab-ab47"
}

run "default_deployment" {
  command = plan

  assert {
    condition     = azurerm_service_plan.functions.sku_name == "FC1" && azurerm_function_app_flex_consumption.service.runtime_name == "node" && azurerm_function_app_flex_consumption.service.runtime_version == "22" && azurerm_function_app_flex_consumption.service.https_only
    error_message = "The deployment must support the existing Node.js 22 service on Flex Consumption over HTTPS."
  }

  assert {
    condition     = length(azurerm_function_app_flex_consumption.service.site_config[0].cors) == 0
    error_message = "CORS must remain disabled when no browser origins are configured."
  }

  assert {
    condition     = output.function_app_name == "pipeline-lab-ps47-func" && output.resource_group_name == "pipeline-lab-ps47-rg"
    error_message = "Deployment outputs must follow the documented naming convention."
  }
}

run "frontend_cors" {
  command = plan

  variables {
    cors_allowed_origins = ["http://localhost:5173"]
  }

  assert {
    condition     = azurerm_function_app_flex_consumption.service.site_config[0].cors[0].allowed_origins == toset(["http://localhost:5173"])
    error_message = "The configured frontend origin must be allowed by CORS."
  }
}

run "invalid_resource_name" {
  command = plan

  variables {
    name_prefix = "Invalid_Prefix"
  }

  expect_failures = [var.name_prefix]
}
