variable "name" {
  description = "Name of the Azure Container App."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group in which the Azure Container App will be created."
  type        = string
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

variable "identity_type" {
  description = "Type of identity to use for the Azure service plan."
  type        = string
  default     = ""
}

variable "user_assigned_identity_ids" {
  description = "List of user assigned identity IDs for the Azure service plan."
  type        = list(string)
  default     = []
}

variable "environment_resource_group_name" {
  description = "Name of the resource group in which the Azure Container App Environment has been created."
  type        = string
  default     = ""
}

variable "environment_name" {
  description = "Name of the Azure Container App Environment."
  type        = string
}

variable "revision_mode" {
  description = "The revision mode of the Container App. Possible values are 'Single' and 'Multiple'."
  type        = string
  default     = "Single"
}

variable "init_container" {
  description = "Configuration for the init container within the Azure Container App."
  type = object({
    name   = string
    image  = string
    cpu    = number
    memory = string
  })
  default = null
}

variable "container" {
  description = "Configuration for the container within the Azure Container App."
  type = object({
    name    = string
    image   = string
    cpu     = number
    memory  = string
    args    = optional(list(string))
    command = optional(list(string))
    env = optional(list(object({
      name        = string
      secret_name = optional(string, "")
      value       = optional(string, "")
    })))

  })
  default = {
    name   = "examplecontainerapp"
    image  = "mcr.microsoft.com/k8se/quickstart:latest"
    cpu    = 0.25
    memory = "0.5Gi"
  }
}

variable "max_replicas" {
  description = "Maximum number of replicas for the container app."
  type        = number
  default     = 1
}

variable "min_replicas" {
  description = "Minimum number of replicas for the container app."
  type        = number
  default     = 1
}

variable "revision_suffix" {
  description = "The suffix to append to the revision name."
  type        = string
  default     = "latest"
}