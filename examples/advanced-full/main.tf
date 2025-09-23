resource "azurerm_resource_group" "this" {
  name     = "rg-container-app-example"
  location = "East US 2"
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "law-example"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 180
  daily_quota_gb      = 10

  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_application_insights" "this" {
  name                = "ai-example"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.this.id

  depends_on = [azurerm_log_analytics_workspace.this]
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-example"
  address_space       = ["192.168.0.0/16"]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_subnet" "container_apps" {
  name                 = "subnet-container-apps"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["192.168.1.0/21"]

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

resource "azurerm_key_vault" "this" {
  name                       = "kv-advfull-${random_string.suffix.result}"
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.this.principal_id

    secret_permissions = [
      "Get"
    ]
  }

  depends_on = [azurerm_resource_group.this, azurerm_user_assigned_identity.this]
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault_secret" "db_connection" {
  name         = "db-connection-string"
  value        = "Server=tcp:advfullserver.database.windows.net;Database=advfulldb;User ID=admin;Password=ComplexPassword123!;"
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [azurerm_key_vault.this]
}

resource "azurerm_storage_account" "this" {
  name                     = "stadvfull${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_container_registry" "this" {
  name                = "cradadvfull${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "Basic"
  admin_enabled       = true

  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_container_app_environment" "this" {
  name                       = "cae-example"
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  infrastructure_subnet_id   = azurerm_subnet.container_apps.id

  depends_on = [
    azurerm_resource_group.this, 
    azurerm_log_analytics_workspace.this, 
    azurerm_subnet.container_apps
  ]
}

module "frontend_container_app" {
  depends_on = [azurerm_container_app_environment.this]
  source = "../.."

  name                            = "ca-frontend-advfull"
  resource_group_name             = azurerm_resource_group.this.name
  container_app_environment_id    = azurerm_container_app_environment.this.id
  environment_name                = azurerm_container_app_environment.this.name
  environment_resource_group_name = ""
  revision_mode                   = "Multiple"
  max_inactive_revisions          = 3

  identity = {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  secret = [
    {
      name                = "acr-password"
      value               = azurerm_container_registry.this.admin_password
      identity            = ""
      key_vault_secret_id = ""
    }
  ]

  registry = [
    {
      server               = azurerm_container_registry.this.login_server
      username             = azurerm_container_registry.this.admin_username
      password_secret_name = "acr-password"
      identity             = ""
    }
  ]

  container = [
    {
      name              = "frontend"
      image             = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu               = 0.5
      memory            = "1Gi"
      args              = []
      command           = []
      ephemeral_storage = ""
      
      env = [
        {
          name        = "API_ENDPOINT"
          secret_name = ""
          value       = "https://ca-api-advfull.${azurerm_container_app_environment.this.default_domain}"
        },
        {
          name        = "NODE_ENV"
          secret_name = ""
          value       = "production"
        },
        {
          name        = "APPINSIGHTS_INSTRUMENTATIONKEY"
          secret_name = ""
          value       = azurerm_application_insights.this.instrumentation_key
        }
      ]
      
      liveness_probe = {
        failure_count_threshold = 3
        initial_delay          = 30
        interval_seconds       = 30
        path                   = "/"
        port                   = 8080
        timeout                = 5
        transport              = "HTTP"
        host                   = ""
        header                 = []
      }
      
      readiness_probe = {
        failure_count_threshold = 3
        initial_delay          = 10
        interval_seconds       = 10
        path                   = "/"
        port                   = 8080
        success_count_threshold = 1
        timeout                = 3
        transport              = "HTTP"
        host                   = ""
        header                 = []
      }
      
      startup_probe = {
        failure_count_threshold = 10
        initial_delay          = 0
        interval_seconds       = 5
        path                   = "/"
        port                   = 8080
        timeout                = 3
        transport              = "HTTP"
        host                   = ""
        header                 = []
      }
      
      volume_mounts = []
    }
  ]

  ingress = {
    allow_insecure_connections = false
    external_enabled          = true
    target_port               = 8080
    exposed_port              = null
    transport                 = "http"
    client_certificate_mode   = ""
    
    cors = {
      allowed_origins           = ["*"]
      allow_credentials_enabled = true
      allowed_headers          = ["*"]
      allowed_methods          = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
      exposed_headers          = []
      max_age_in_seconds       = 300
    }
    
    ip_security_restriction = []
    
    traffic_weight = [
      {
        label           = "production"
        latest_revision = true
        revision_suffix = ""
        percentage      = 100
      }
    ]
  }

  http_scale_rule = [
    {
      name                = "http-requests"
      concurrent_requests = 10
      authentication      = []
    }
  ]

  tags = {
    Environment          = "AdvancedFull"
    ManagedBy           = "Terraform"

  }
}

module "api_container_app" {
  depends_on = [azurerm_container_app_environment.this, module.frontend_container_app]
  source = "../.."

  name                            = "ca-api-advfull"
  resource_group_name             = azurerm_resource_group.this.name
  container_app_environment_id    = azurerm_container_app_environment.this.id
  environment_name                = azurerm_container_app_environment.this.name
  environment_resource_group_name = ""
  revision_mode                   = "Single"
  max_inactive_revisions          = 1

  identity = {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  secret = [
    {
      name                = "db-connection-kv"
      value               = ""
      identity            = azurerm_user_assigned_identity.this.id
      key_vault_secret_id = azurerm_key_vault_secret.db_connection.id
    },
    {
      name                = "storage-key"
      value               = azurerm_storage_account.this.primary_access_key
      identity            = ""
      key_vault_secret_id = ""
    }
  ]

  container = [
    {
      name              = "api"
      image             = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu               = 1.0
      memory            = "2Gi"
      args              = []
      command           = []
      ephemeral_storage = "1Gi"
      
      env = [
        {
          name        = "DATABASE_CONNECTION"
          secret_name = "db-connection-kv"
          value       = ""
        },
        {
          name        = "STORAGE_CONNECTION"
          secret_name = "storage-key"
          value       = ""
        },
        {
          name        = "ASPNETCORE_ENVIRONMENT"
          secret_name = ""
          value       = "Production"
        },
        {
          name        = "APPINSIGHTS_INSTRUMENTATIONKEY"
          secret_name = ""
          value       = azurerm_application_insights.this.instrumentation_key
        }
      ]
      
      liveness_probe = {
        failure_count_threshold = 5
        initial_delay          = 60
        interval_seconds       = 30
        path                   = "/health"
        port                   = 8080
        timeout                = 10
        transport              = "HTTP"
        host                   = ""
        header = [
          {
            name  = "Custom-Header"
            value = "liveness"
          }
        ]
      }
      
      readiness_probe = {
        failure_count_threshold = 3
        initial_delay          = 20
        interval_seconds       = 10
        path                   = "/ready"
        port                   = 8080
        success_count_threshold = 1
        timeout                = 5
        transport              = "HTTP"
        host                   = ""
        header = [
          {
            name  = "Custom-Header"
            value = "readiness"
          }
        ]
      }
      
      startup_probe = {
        failure_count_threshold = 30
        initial_delay          = 0
        interval_seconds       = 10
        path                   = "/startup"
        port                   = 8080
        timeout                = 5
        transport              = "HTTP"
        host                   = ""
        header                 = []
      }
      
      volume_mounts = []
    }
  ]

  ingress = {
    allow_insecure_connections = false
    external_enabled          = false
    target_port               = 8080
    exposed_port              = null
    transport                 = "http"
    client_certificate_mode   = ""
    cors                      = null
    ip_security_restriction   = []
    
    traffic_weight = [
      {
        label           = "stable"
        latest_revision = true
        revision_suffix = ""
        percentage      = 100
      }
    ]
  }

  custom_scale_rule = [
    {
      name             = "cpu-scaling"
      custom_rule_type = "cpu"
      metadata = {
        type  = "Utilization"
        value = "70"
      }
      authentication = []
    }
  ]

  tags = {
    Environment          = "AdvancedFull"
    ManagedBy           = "Terraform"

  }
}