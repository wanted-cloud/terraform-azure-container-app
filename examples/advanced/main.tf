resource "azurerm_resource_group" "this" {
  name     = "rg-container-app-example"
  location = "North Europe"
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "law-example"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 90

  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-example"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_subnet" "container_apps" {
  name                 = "subnet-container-apps"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.1.0/23"]

  delegation {
    name = "Microsoft.App.environments"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }

  depends_on = [azurerm_virtual_network.this]
}

resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = "uai-example"
  resource_group_name = azurerm_resource_group.this.name

  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_container_app_environment" "this" {
  name                       = "cae-example"
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  infrastructure_subnet_id   = azurerm_subnet.container_apps.id

  depends_on = [azurerm_resource_group.this, azurerm_log_analytics_workspace.this, azurerm_subnet.container_apps]
}

module "container_app" {
  depends_on = [azurerm_container_app_environment.this]
  source = "../.."

  name                            = "ca-example"
  resource_group_name             = azurerm_resource_group.this.name
  container_app_environment_id    = azurerm_container_app_environment.this.id
  environment_name                = azurerm_container_app_environment.this.name
  environment_resource_group_name = ""
  revision_mode                   = "Multiple"
  max_inactive_revisions          = 5

  identity = {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  secret = [
    {
      name                = "db-connection-string"
      value               = "Server=tcp:myserver.database.windows.net;Database=mydb;"
      identity            = ""
      key_vault_secret_id = ""
    }
  ]

  container = [
    {
      name              = "api-service"
      image             = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu               = 0.5
      memory            = "1Gi"
      args              = []
      command           = []
      ephemeral_storage = ""
      
      env = [
        {
          name        = "DATABASE_CONNECTION"
          secret_name = "db-connection-string"
          value       = ""
        },
        {
          name        = "ENVIRONMENT"
          secret_name = ""
          value       = "production"
        }
      ]
      
      liveness_probe = {
        failure_count_threshold = 3
        initial_delay          = 10
        interval_seconds       = 30
        path                   = "/health"
        port                   = 8080
        timeout                = 5
        transport              = "HTTP"
        host                   = ""
        header                 = []
      }
      
      readiness_probe = {
        failure_count_threshold = 3
        initial_delay          = 5
        interval_seconds       = 10
        path                   = "/ready"
        port                   = 8080
        success_count_threshold = 1
        timeout                = 3
        transport              = "HTTP"
        host                   = ""
        header                 = []
      }
      
      startup_probe   = null
      volume_mounts   = []
    }
  ]

  ingress = {
    allow_insecure_connections = false
    external_enabled          = true
    target_port               = 8080
    exposed_port              = null
    transport                 = "http"
    client_certificate_mode   = ""
    cors                      = null
    ip_security_restriction   = []
    traffic_weight = [
      {
        label           = "blue"
        latest_revision = false
        revision_suffix = "blue"
        percentage      = 80
      },
      {
        label           = "green"
        latest_revision = true
        revision_suffix = ""
        percentage      = 20
      }
    ]
  }

  tags = {
    Environment = "Advanced"
    ManagedBy   = "Terraform"
  }
}