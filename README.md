<!-- BEGIN_TF_DOCS -->
# wanted-cloud/terraform-azure-container-app

Terraform building block managing Azure Container App and its related resources.

## Table of contents

- [Requirements](#requirements)
- [Providers](#providers)
- [Variables](#inputs)
- [Outputs](#outputs)
- [Resources](#resources)
- [Usage](#usage)
- [Contributing](#contributing)

## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.11)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>=4.20.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>=4.20.0)

## Required Inputs

The following input variables are required:

### <a name="input_container"></a> [container](#input\_container)

Description: Configuration for the container within the Azure Container App.

Type:

```hcl
object({
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
```

### <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name)

Description: Name of the Azure Container App Environment.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: Name of the Azure Container App.

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: Name of the resource group in which the Azure Container App will be created.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_environment_resource_group_name"></a> [environment\_resource\_group\_name](#input\_environment\_resource\_group\_name)

Description: Name of the resource group in which the Azure Container App Environment has been created.

Type: `string`

Default: `""`

### <a name="input_identity_type"></a> [identity\_type](#input\_identity\_type)

Description: Type of identity to use for the Azure service plan.

Type: `string`

Default: `""`

### <a name="input_init_container"></a> [init\_container](#input\_init\_container)

Description: Configuration for the init container within the Azure Container App.

Type:

```hcl
object({
    name   = string
    image  = string
    cpu    = number
    memory = string
  })
```

Default: `null`

### <a name="input_location"></a> [location](#input\_location)

Description: Location of the Azure Container App.

Type: `string`

Default: `""`

### <a name="input_max_replicas"></a> [max\_replicas](#input\_max\_replicas)

Description: Maximum number of replicas for the container app.

Type: `number`

Default: `1`

### <a name="input_metadata"></a> [metadata](#input\_metadata)

Description: Metadata definitions for the module, this is optional construct allowing override of the module defaults defintions of validation expressions, error messages, resource timeouts and default tags.

Type:

```hcl
object({
    resource_timeouts = optional(
      map(
        object({
          create = optional(string, "30m")
          read   = optional(string, "5m")
          update = optional(string, "30m")
          delete = optional(string, "30m")
        })
      ), {}
    )
    tags                     = optional(map(string), {})
    validator_error_messages = optional(map(string), {})
    validator_expressions    = optional(map(string), {})
  })
```

Default: `{}`

### <a name="input_min_replicas"></a> [min\_replicas](#input\_min\_replicas)

Description: Minimum number of replicas for the container app.

Type: `number`

Default: `1`

### <a name="input_revision_mode"></a> [revision\_mode](#input\_revision\_mode)

Description: The revision mode of the Container App. Possible values are 'Single' and 'Multiple'.

Type: `string`

Default: `"Single"`

### <a name="input_revision_suffix"></a> [revision\_suffix](#input\_revision\_suffix)

Description: The suffix to append to the revision name.

Type: `string`

Default: `"latest"`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: A map of tags to assign to the resource.

Type: `map(string)`

Default: `{}`

### <a name="input_user_assigned_identity_ids"></a> [user\_assigned\_identity\_ids](#input\_user\_assigned\_identity\_ids)

Description: List of user assigned identity IDs for the Azure service plan.

Type: `list(string)`

Default: `[]`

## Outputs

The following outputs are exported:

### <a name="output_container_app_id"></a> [container\_app\_id](#output\_container\_app\_id)

Description: n/a

## Resources

The following resources are used by this module:

- [azurerm_container_app.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app) (resource)
- [azurerm_container_app_environment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/container_app_environment) (data source)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) (data source)

## Usage

> For more detailed examples navigate to `examples` folder of this repository.

Module was also published via Terraform Registry and can be used as a module from the registry.

```hcl
module "example" {
  source  = "wanted-cloud/..."
  version = "x.y.z"
}
```

### Basic usage example

The minimal usage for the module is as follows:

```hcl
module "template" {
    source = "../.."
}
```
## Contributing

_Contributions are welcomed and must follow [Code of Conduct](https://github.com/wanted-cloud/.github?tab=coc-ov-file) and common [Contributions guidelines](https://github.com/wanted-cloud/.github/blob/main/docs/CONTRIBUTING.md)._

> If you'd like to report security issue please follow [security guidelines](https://github.com/wanted-cloud/.github?tab=security-ov-file).
---
<sup><sub>_2025 &copy; All rights reserved - WANTED.solutions s.r.o._</sub></sup>
<!-- END_TF_DOCS -->