variable "name" {
  description = "Name of the Azure Container App."
  type        = string
}

variable "environment_name" {
  description = "Name of the Container App Environment."
  type        = string
}

variable "environment_resource_group_name" {
  description = "Name of the resource group containing the Container App Environment. If not specified, uses the same resource group as the Container App."
  type        = string
  default     = ""
}

variable "resource_group_name" {
  description = "Name of the resource group in which the Azure Container App will be created."
  type        = string
}

variable "container_app_environment_id" {
  description = "The ID of the Container App Environment within which this Container App should exist."
  type        = string
}

variable "revision_mode" {
  description = "The revisions operational mode for the Container App. Possible values are Single and Multiple."
  type        = string
  default     = "Single"
}

variable "location" {
  description = "Location of the Azure Container App."
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to assign to the resource."
  type        = map(string)
  default     = {}
}

variable "workload_profile_name" {
  description = "The name of the Workload Profile in the Container App Environment to place this Container App."
  type        = string
  default     = ""
}

variable "max_inactive_revisions" {
  description = "The maximum of inactive revisions allowed for this Container App."
  type        = number
  default     = 10
}

variable "identity" {
  description = "An identity block for managed identity configuration."
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })
  default = null
}

variable "secret" {
  description = "One or more secret blocks."
  type = list(object({
    name                = string
    identity            = optional(string, "")
    key_vault_secret_id = optional(string, "")
    value               = optional(string, "")
  }))
  default = []
}

variable "dapr" {
  description = "A dapr block for Dapr configuration."
  type = object({
    app_id       = string
    app_port     = optional(number, null)
    app_protocol = optional(string, "http")
  })
  default = null
}

variable "ingress" {
  description = "An ingress block for traffic routing."
  type = object({
    allow_insecure_connections = optional(bool, false)
    external_enabled           = optional(bool, false)
    target_port                = number
    exposed_port               = optional(number, null)
    transport                  = optional(string, "auto")
    client_certificate_mode    = optional(string, "")

    cors = optional(object({
      allowed_origins           = list(string)
      allow_credentials_enabled = optional(bool, false)
      allowed_headers           = optional(list(string), [])
      allowed_methods           = optional(list(string), [])
      exposed_headers           = optional(list(string), [])
      max_age_in_seconds        = optional(number, 0)
    }), null)

    ip_security_restriction = optional(list(object({
      action           = string
      description      = optional(string, "")
      ip_address_range = string
      name             = string
    })), [])

    traffic_weight = list(object({
      label           = optional(string, "")
      latest_revision = optional(bool, false)
      revision_suffix = optional(string, "")
      percentage      = number
    }))
  })
  default = null
}

variable "registry" {
  description = "Registry blocks for container registries."
  type = list(object({
    server               = string
    identity             = optional(string, "")
    password_secret_name = optional(string, "")
    username             = optional(string, "")
  }))
  default = []
}

variable "max_replicas" {
  description = "The maximum number of replicas for this container."
  type        = number
  default     = 1
}

variable "min_replicas" {
  description = "The minimum number of replicas for this container."
  type        = number
  default     = 1
}

variable "revision_suffix" {
  description = "The suffix for the revision."
  type        = string
  default     = ""
}

variable "termination_grace_period_seconds" {
  description = "The time in seconds after the container is sent the termination signal before the process if forcibly killed."
  type        = number
  default     = 30
}

variable "container" {
  description = "One or more container blocks."
  type = list(object({
    name              = string
    image             = string
    cpu               = number
    memory            = string
    args              = optional(list(string), [])
    command           = optional(list(string), [])
    ephemeral_storage = optional(string, "")

    env = optional(list(object({
      name        = string
      secret_name = optional(string, "")
      value       = optional(string, "")
    })), [])

    liveness_probe = optional(object({
      failure_count_threshold = optional(number, 3)
      initial_delay           = optional(number, 1)
      interval_seconds        = optional(number, 10)
      path                    = optional(string, "/")
      port                    = number
      timeout                 = optional(number, 1)
      transport               = string
      host                    = optional(string, "")

      header = optional(list(object({
        name  = string
        value = string
      })), [])
    }), null)

    readiness_probe = optional(object({
      failure_count_threshold = optional(number, 3)
      initial_delay           = optional(number, 0)
      interval_seconds        = optional(number, 10)
      path                    = optional(string, "/")
      port                    = number
      success_count_threshold = optional(number, 3)
      timeout                 = optional(number, 1)
      transport               = string
      host                    = optional(string, "")

      header = optional(list(object({
        name  = string
        value = string
      })), [])
    }), null)

    startup_probe = optional(object({
      failure_count_threshold = optional(number, 3)
      initial_delay           = optional(number, 0)
      interval_seconds        = optional(number, 10)
      path                    = optional(string, "/")
      port                    = number
      timeout                 = optional(number, 1)
      transport               = string
      host                    = optional(string, "")

      header = optional(list(object({
        name  = string
        value = string
      })), [])
    }), null)

    volume_mounts = optional(list(object({
      name     = string
      path     = string
      sub_path = optional(string, "")
    })), [])
  }))
}

variable "init_container" {
  description = "The definition of an init container that is part of the group."
  type = list(object({
    name              = string
    image             = string
    cpu               = optional(number, 0.25)
    memory            = optional(string, "0.5Gi")
    args              = optional(list(string), [])
    command           = optional(list(string), [])
    ephemeral_storage = optional(string, "")

    env = optional(list(object({
      name        = string
      secret_name = optional(string, "")
      value       = optional(string, "")
    })), [])

    volume_mounts = optional(list(object({
      name     = string
      path     = string
      sub_path = optional(string, "")
    })), [])
  }))
  default = []
}

variable "volume" {
  description = "A volume block."
  type = list(object({
    name          = string
    storage_name  = optional(string, "")
    storage_type  = optional(string, "EmptyDir")
    mount_options = optional(string, "")
  }))
  default = []
}

variable "azure_queue_scale_rule" {
  description = "One or more azure_queue_scale_rule blocks."
  type = list(object({
    name         = string
    queue_name   = string
    queue_length = number

    authentication = list(object({
      secret_name       = string
      trigger_parameter = string
    }))
  }))
  default = []
}

variable "custom_scale_rule" {
  description = "One or more custom_scale_rule blocks."
  type = list(object({
    name             = string
    custom_rule_type = string
    metadata         = map(string)

    authentication = optional(list(object({
      secret_name       = string
      trigger_parameter = string
    })), [])
  }))
  default = []
}

variable "http_scale_rule" {
  description = "One or more http_scale_rule blocks."
  type = list(object({
    name                = string
    concurrent_requests = number

    authentication = optional(list(object({
      secret_name       = string
      trigger_parameter = string
    })), [])
  }))
  default = []
}

variable "tcp_scale_rule" {
  description = "One or more tcp_scale_rule blocks."
  type = list(object({
    name                = string
    concurrent_requests = number

    authentication = optional(list(object({
      secret_name       = string
      trigger_parameter = string
    })), [])
  }))
  default = []
}