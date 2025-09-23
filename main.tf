/*
 * # wanted-cloud/terraform-azure-container-app
 * 
 * Terraform building block managing Azure Container App and its related resources.
 */

resource "azurerm_container_app" "this" {
  name                         = var.name
  container_app_environment_id = var.container_app_environment_id
  resource_group_name          = data.azurerm_resource_group.this.name
  revision_mode                = var.revision_mode
  tags                         = var.tags

  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  template {
    dynamic "init_container" {
      for_each = var.init_container
      content {
        name   = init_container.value.name
        image  = init_container.value.image
        cpu    = init_container.value.cpu
        memory = init_container.value.memory
      }
    }

    dynamic "container" {
      for_each = var.container
      content {
        name   = container.value.name
        image  = container.value.image
        cpu    = container.value.cpu
        memory = container.value.memory
        args   = container.value.args
      }
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