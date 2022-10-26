# Virtual Private Cloud (VPC) Terraform module for Yandex.Cloud

## Features

- Create Network and subnets in your folder
- Subnets can be public with NAT gateway and privite
- Configure your degault security group
- Easy to use in other resources via outputs

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

| Name                                                                     | Version  |
| ------------------------------------------------------------------------ | -------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.0.0 |
| <a name="requirement_yandex"></a> [yandex](#requirement_yandex)          | > 0.8    |

## Providers

| Name                                                      | Version |
| --------------------------------------------------------- | ------- |
| <a name="provider_yandex"></a> [yandex](#provider_yandex) | 0.81.0  |

## Modules

No modules.

## Resources

| Name                                                                                                                                                         | Type        |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------- |
| [yandex_vpc_default_security_group.default_sg](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_default_security_group) | resource    |
| [yandex_vpc_gateway.egress-gateway](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_gateway)                           | resource    |
| [yandex_vpc_network.this](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_network)                                     | resource    |
| [yandex_vpc_route_table.private](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_route_table)                          | resource    |
| [yandex_vpc_route_table.public](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_route_table)                           | resource    |
| [yandex_vpc_subnet.private](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_subnet)                                    | resource    |
| [yandex_vpc_subnet.public](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_subnet)                                     | resource    |
| [yandex_client_config.client](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/data-sources/client_config)                            | data source |

## Inputs

| Name                                                                                                | Description                                                                                   | Type                                                                                           | Default               | Required |
| --------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- | --------------------- | :------: |
| <a name="input_create_vpc"></a> [create_vpc](#input_create_vpc)                                     | Create VCP object or not. If false existing vpc_id is required                                | `bool`                                                                                         | `true`                |    no    |
| <a name="input_domain_name"></a> [domain_name](#input_domain_name)                                  | Domain name to be added to DHCP options                                                       | `string`                                                                                       | `null`                |    no    |
| <a name="input_domain_name_servers"></a> [domain_name_servers](#input_domain_name_servers)          | Domain name servers to be added to DHCP options                                               | `list(string)`                                                                                 | `[]`                  |    no    |
| <a name="input_folder_id"></a> [folder_id](#input_folder_id)                                        | Folder-ID where the resources will be created                                                 | `string`                                                                                       | `null`                |    no    |
| <a name="input_labels"></a> [labels](#input_labels)                                                 | A set of key/value label pairs to assign.                                                     | `map(string)`                                                                                  | `null`                |    no    |
| <a name="input_network_description"></a> [network_description](#input_network_description)          | An optional description of this resource. Provide this property when you create the resource. | `string`                                                                                       | `"terraform-created"` |    no    |
| <a name="input_network_name"></a> [network_name](#input_network_name)                               | Prefix to be used on all the resources as identifier                                          | `string`                                                                                       | n/a                   |   yes    |
| <a name="input_ntp_servers"></a> [ntp_servers](#input_ntp_servers)                                  | NTP Servers for subnets                                                                       | `list(string)`                                                                                 | `[]`                  |    no    |
| <a name="input_private_subnets"></a> [private_subnets](#input_private_subnets)                      | Describe your private subnets preferences                                                     | <pre>list(object({<br> zone = string<br> v4_cidr_blocks = string<br> }))</pre>                 | `null`                |    no    |
| <a name="input_public_subnets"></a> [public_subnets](#input_public_subnets)                         | Describe your public subnets preferences                                                      | <pre>list(object({<br> zone = string<br> v4_cidr_blocks = string<br> }))</pre>                 | `null`                |    no    |
| <a name="input_routes_private_subnets"></a> [routes_private_subnets](#input_routes_private_subnets) | Describe your routes preferences for public subnets                                           | <pre>list(object({<br> destination_prefix = string<br> next_hop_address = string<br> }))</pre> | `null`                |    no    |
| <a name="input_routes_public_subnets"></a> [routes_public_subnets](#input_routes_public_subnets)    | Describe your routes preferences for public subnets                                           | <pre>list(object({<br> destination_prefix = string<br> next_hop_address = string<br> }))</pre> | `null`                |    no    |
| <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id)                                                 | Existing network_id(vpc-id) where resources be created                                        | `string`                                                                                       | `null`                |    no    |

## Outputs

| Name                                                                                                  | Description                                                      |
| ----------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| <a name="output_private_subnets"></a> [private_subnets](#output_private_subnets)                      | List of maps of subnets used in vpc network: key = v4_cidr_block |
| <a name="output_private_v4_cidr_blocks"></a> [private_v4_cidr_blocks](#output_private_v4_cidr_blocks) | List of v4_cidr_blocks used in vpc network                       |
| <a name="output_public_subnets"></a> [public_subnets](#output_public_subnets)                         | List of maps of subnets used in vpc network: key = v4_cidr_block |
| <a name="output_public_v4_cidr_blocks"></a> [public_v4_cidr_blocks](#output_public_v4_cidr_blocks)    | List of v4_cidr_blocks used in vpc network                       |
| <a name="output_vpc_id"></a> [vpc_id](#output_vpc_id)                                                 | ID of created network for internal communications                |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
