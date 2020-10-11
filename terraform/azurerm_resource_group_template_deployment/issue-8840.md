<!---
Please note the following potential times when an issue might be in Terraform core:

* [Configuration Language](https://www.terraform.io/docs/configuration/index.html) or resource ordering issues
* [State](https://www.terraform.io/docs/state/index.html) and [State Backend](https://www.terraform.io/docs/backends/index.html) issues
* [Provisioner](https://www.terraform.io/docs/provisioners/index.html) issues
* [Registry](https://registry.terraform.io/) issues
* Spans resources across multiple providers

If you are running into one of these scenarios, we recommend opening an issue in the [Terraform core repository](https://github.com/hashicorp/terraform/) instead.
--->

<!--- Please keep this note for the community --->

### Community Note

* Please vote on this issue by adding a 👍 [reaction](https://blog.github.com/2016-03-10-add-reactions-to-pull-requests-issues-and-comments/) to the original issue to help the community and maintainers prioritize this request
* Please do not leave "+1" or "me too" comments, they generate extra noise for issue followers and do not help prioritize the request
* If you are interested in working on this issue or have submitted a pull request, please leave a comment

<!--- Thank you for keeping this note for the community --->

### Terraform (and AzureRM Provider) Version

<!--- Please run `terraform -v` to show the Terraform core version and provider version(s). If you are not running the latest version of Terraform or the provider, please upgrade because your issue may have already been fixed. [Terraform documentation on provider versioning](https://www.terraform.io/docs/configuration/providers.html#provider-versions). --->
```
terraform -v
Terraform v0.13.4
+ provider registry.terraform.io/hashicorp/azurerm v2.31.0
+ provider registry.terraform.io/hashicorp/random v2.3.0
```

### Affected Resource(s)

<!--- Please list the affected resources and data sources. --->

* `azurerm_resource_group_template_deployment`

Thanks for creating an resource that can destroy ARM resources!

### Terraform Configuration Files

<!--- Information about code formatting: https://help.github.com/articles/basic-writing-and-formatting-syntax/#quoting-code --->

```hcl
locals {
  suffix                       = random_string.suffix.result
  tags                         = map(
    "application",               "Dev/Test Lab",
    "environment",               "repro",
    "provisioner",               "terraform",
    "suffix",                    local.suffix,
    "workspace",                 terraform.workspace
  )
}
# Random resource suffix, this will prevent name collisions when creating resources in parallel
resource random_string suffix {
  length                       = 4
  upper                        = false
  lower                        = true
  number                       = false
  special                      = false
}

resource azurerm_resource_group lab_resource_group {
  name                         = "lab-${terraform.workspace}-${local.suffix}"
  location                     = var.location
  tags                         = local.tags
}

resource azurerm_dev_test_lab lab {
  name                         = "${azurerm_resource_group.lab_resource_group.name}-lab"
  location                     = azurerm_resource_group.lab_resource_group.location
  resource_group_name          = azurerm_resource_group.lab_resource_group.name

  tags                         = local.tags
}

resource azurerm_virtual_network custom_network {
  name                         = "${azurerm_resource_group.lab_resource_group.name}-network"
  location                     = azurerm_resource_group.lab_resource_group.location
  resource_group_name          = azurerm_resource_group.lab_resource_group.name
  address_space                = ["10.1.0.0/16"]

  tags                         = local.tags
}

resource azurerm_subnet custom_subnet {
  name                         = "CustomSubnet"
  virtual_network_name         = azurerm_virtual_network.custom_network.name
  resource_group_name          = azurerm_virtual_network.custom_network.resource_group_name
  address_prefixes             = ["10.1.1.0/24"]
}

resource azurerm_resource_group_template_deployment custom_network_association {
  name                         = "${azurerm_resource_group.lab_resource_group.name}-network-association"
  resource_group_name          = azurerm_resource_group.lab_resource_group.name
  deployment_mode              = "Incremental"

  template_content             = file("${path.module}/lab-network-association.json")
  parameters_content           = templatefile("${path.module}/lab-network-association-parameters.json",
    {
      lab_id                   = azurerm_dev_test_lab.lab.id
      virtual_network_id       = azurerm_virtual_network.custom_network.id
      virtual_network_subnet_id= azurerm_subnet.custom_subnet.id
    }
  )

  debug_level                  = "requestContent"
}
```
lab-network-association.json:
```
{
	"$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
	"contentVersion": "1.0.0.0",
	"parameters": {
		"labId": {
			"type": "string"
		},
		"virtualNetworkId": {
			"type": "string"
		},
		"virtualNetworkSubnetId": {
			"type": "string"
		}
	},
	"variables": {
		"labVirtualNetworkId": "[concat(parameters('labId'),'/virtualnetworks/', split(parameters('virtualNetworkId'),'/')[8])]"
	},
	"resources": [
		{
			"apiVersion": "2016-05-15",
			"type": "Microsoft.DevTestLab/labs",
            "id": "[parameters('labId')]",
            "name": "[split(parameters('labId'),'/')[8]]",
			"location": "[resourceGroup().location]",
			"resources": [
                {
                    "apiVersion": "2016-05-15",
                    "id": "[variables('labVirtualNetworkId')]",
                    "name": "[split(parameters('virtualNetworkId'),'/')[8]]",
                    "type": "virtualNetworks",
                    "dependsOn": [
                        "[parameters('labId')]"
                    ],
                    "properties": {
                        "description": "Existing Compute virtual network associated as part of the lab",
                        "externalProviderResourceId": "[parameters('virtualNetworkId')]",
                        "subnetOverrides": [
                            {
                                "name": "[split(parameters('virtualNetworkSubnetId'),'/')[10]]",
                                "resourceId": "[parameters('virtualNetworkSubnetId')]",
                                "useInVmCreationPermission": "Allow",
                                "usePublicIpAddressPermission": "Allow"
                            }
                        ]
                    }
                }
			]
        }
	],
    "outputs": {
        "labVirtualNetworkId": {
            "type": "string",
            "value": "[variables('labVirtualNetworkId')]"
        }
    }
}
```
lab-network-association-parameters.json:
```
{
    "labId": {
        "value": "${lab_id}"
    },
    "virtualNetworkId": {
        "value": "${virtual_network_id}"
    },
    "virtualNetworkSubnetId": {
        "value": "${virtual_network_subnet_id}"
    }
}
```


### Debug Output

<!---
Please provide a link to a GitHub Gist containing the complete debug output. Please do NOT paste the debug output in the issue; just paste a link to the Gist.

To obtain the debug output, see the [Terraform documentation on debugging](https://www.terraform.io/docs/internals/debugging.html).
--->

### Panic Output

<!--- If Terraform produced a panic, please provide a link to a GitHub Gist containing the output of the `crash.log`. --->

### Expected Behavior

<!--- What should have happened? --->
Running 'terraform apply' a second time should be idempotent and succeed as the first 'terraform apply' also succeeeds

### Actual Behavior

<!--- What actually happened? --->
Running 'terraform apply' a second time yields an error:
```
Error: validating Template Deployment "lab-default-vlac-network-association" (Resource Group "lab-default-vlac"): requesting validating: resources.DeploymentsClient#Validate: Failure sending request: StatusCode=400 -- Original Error: Code="InvalidTemplate" Message="Deployment template validation failed: 'The value for the template parameter 'labId' at line '1' and column '266' is not provided. Please see https://aka.ms/resource-manager-parameter-files for usage details.'." AdditionalInfo=[{"info":{"lineNumber":1,"linePosition":266,"path":"properties.template.parameters.labId"},"type":"TemplateViolation"}]

  on main.tf line 50, in resource "azurerm_resource_group_template_deployment" "custom_network_association":
  50: resource azurerm_resource_group_template_deployment custom_network_association {
```

### Steps to Reproduce

<!--- Please list the steps required to reproduce the issue. --->

1. `terraform init`
1. `terraform apply`
1. `terraform apply`

### Important Factoids

<!--- Are there anything atypical about your accounts that we should know? For example: Running in a Azure China/Germany/Government? --->

### References

<!---
Information about referencing Github Issues: https://help.github.com/articles/basic-writing-and-formatting-syntax/#referencing-issues-and-pull-requests

Are there any other GitHub issues (open or closed) or pull requests that should be linked here? Such as vendor documentation?
--->

<!-- * #0000 -->
