# Virtual Private Cloud (VPC) Terraform module for Yandex.Cloud
## Features

* Create Network and subnets in your folder.
* Easy to use in other resources via outputs.

### Configure Terraform for Yandex.Cloud 

- Install [YC cli](https://cloud.yandex.com/docs/cli/quickstart)
- Add environment variables for terraform auth in Yandex.Cloud
  
```
export YC_TOKEN=$(yc iam create-token)
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)
``` 
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_yandex"></a> [yandex](#requirement\_yandex) | > 0.5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_yandex"></a> [yandex](#provider\_yandex) | 0.60.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [yandex_vpc_default_security_group.default_sg](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_default_security_group) | resource |
| [yandex_vpc_network.this](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_network) | resource |
| [yandex_vpc_subnet.this](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_subnet) | resource |
| [yandex_client_config.client](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_vpc"></a> [create\_vpc](#input\_create\_vpc) | Create VCP object or not. If false existing vpc\_id is required | `bool` | `true` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name to be added to DHCP options | `string` | `null` | no |
| <a name="input_domain_name_servers"></a> [domain\_name\_servers](#input\_domain\_name\_servers) | Domain name servers to be added to DHCP options | `list(string)` | `[]` | no |
| <a name="input_folder_id"></a> [folder\_id](#input\_folder\_id) | Folder-ID where the resources will be created | `string` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | A set of key/value label pairs to assign. | `map(string)` | `null` | no |
| <a name="input_network_description"></a> [network\_description](#input\_network\_description) | An optional description of this resource. Provide this property when you create the resource. | `string` | `"terraform-created"` | no |
| <a name="input_network_name"></a> [network\_name](#input\_network\_name) | Prefix to be used on all the resources as identifier | `string` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Describe your subnets preferences | <pre>list(object({<br>    zone           = string<br>    v4_cidr_blocks = string<br>  }))</pre> | <pre>[<br>  {<br>    "v4_cidr_blocks": "10.110.0.0/16",<br>    "zone": "ru-central1-a"<br>  },<br>  {<br>    "v4_cidr_blocks": "10.120.0.0/16",<br>    "zone": "ru-central1-b"<br>  },<br>  {<br>    "v4_cidr_blocks": "10.130.0.0/16",<br>    "zone": "ru-central1-c"<br>  }<br>]</pre> | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | Existing network\_id(vpc-id) where resources be created | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_subnets"></a> [subnets](#output\_subnets) | List of maps of subnets used in vpc network: key = v4\_cidr\_block |
| <a name="output_v4_cidr_blocks"></a> [v4\_cidr\_blocks](#output\_v4\_cidr\_blocks) | List of v4\_cidr\_blocks used in vpc network |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of created network for internal communications |
| <a name="output_zones"></a> [zones](#output\_zones) | List of zones used in vpc network |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
