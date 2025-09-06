/*
 * # wanted-cloud/terraform-azure-container-app
 * 
 * Terraform building block managing Azure Container App and its related resources.
 */

resource "azurerm_container_app" "this" {
  name                         = var.name
  container_app_environment_id = data.azurerm_container_app_environment.this.id
  resource_group_name          = data.azurerm_resource_group.this.name
  revision_mode                = var.revision_mode
  tags                         = var.tags

  dynamic "identity" {
    for_each = var.identity_type != "" ? [var.identity_type] : []
    content {
      type         = identity.value
      identity_ids = var.user_assigned_identity_ids
    }
  }

  template {
    dynamic "init_container" {
      for_each = var.init_container != null ? [var.init_container] : []
      content {
        name   = init_container.value.name
        image  = init_container.value.image
        cpu    = init_container.value.cpu
        memory = init_container.value.memory
      }
    }

    container {
      name   = var.container.name
      image  = var.container.image
      cpu    = var.container.cpu
      memory = var.container.memory
      args   = var.container.args
    }
  }

  timeouts {
    create = try(
      local.metadata.resource_timeouts["azurerm_container_app"]["create"],
      local.metadata.resource_timeouts["default"]["create"]
    )
    read = try(
      local.metadata.resource_timeouts["azurerm_container_app"]["read"],
      local.metadata.resource_timeouts["default"]["read"]
    )
    update = try(
      local.metadata.resource_timeouts["azurerm_container_app"]["update"],
      local.metadata.resource_timeouts["default"]["update"]
    )
    delete = try(
      local.metadata.resource_timeouts["azurerm_container_app"]["delete"],
      local.metadata.resource_timeouts["default"]["delete"]
    )
  }
}