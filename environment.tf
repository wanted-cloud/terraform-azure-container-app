data "azurerm_container_app_environment" "this" {
  name                = var.environment_name
  resource_group_name = var.environment_resource_group_name != "" ? var.environment_resource_group_name : data.azurerm_resource_group.this.name
}