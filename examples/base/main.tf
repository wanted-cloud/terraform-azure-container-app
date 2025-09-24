resource "azurerm_resource_group" "this" {
  name     = "rg-container-app-example"
  location = "West Europe"
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "law-example"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_container_app_environment" "this" {
  name                       = "cae-example"
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  depends_on = [azurerm_resource_group.this, azurerm_log_analytics_workspace.this]
}

module "container_app" {
  depends_on = [azurerm_container_app_environment.this]
  source = "../.."

  name                         = "ca-example"
  resource_group_name          = azurerm_resource_group.this.name
  container_app_environment_id = azurerm_container_app_environment.this.id
  environment_name             = azurerm_container_app_environment.this.name 

  container = [
    {
      name   = "hello-world"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  ]

  tags = {
    Environment = "Basic"
    ManagedBy   = "Terraform"
  }
}