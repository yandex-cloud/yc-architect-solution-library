 # Security Groups Terraform module for Yandex.Cloud
## Features

* Create Security Group and rules in your VPC.
* Applicable for FOR_Each cycle. See [example](./example/main.tf)
* Output SG-id for referencing

Use `ingress_rules_with_cidrs` to add rules with ip address ranges.

Use `ingress_rules_with_sg_ids` to add rules with other SGs as traffic source.

Use `self` to add rule "self_security_group" for communication within SG.


### Configure Terraform for Yandex.Cloud 

- Install [YC cli](https://cloud.yandex.com/docs/cli/quickstart)
- Add environment variables for terraform auth in Yandex.Cloud
  
```
export YC_TOKEN=$(yc iam create-token)
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)
``` 

## Requirements

| Name                                                                      | Version  |
| ------------------------------------------------------------------------- | -------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_yandex"></a> [yandex](#requirement\_yandex)          | > 0.6    |

## Providers

| Name                                                       | Version |
| ---------------------------------------------------------- | ------- |
| <a name="provider_yandex"></a> [yandex](#provider\_yandex) | 0.61.0  |

## Modules

No modules.

## Resources

| Name                                                                                                                                                                  | Type        |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [yandex_vpc_security_group.this](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_security_group)                                | resource    |
| [yandex_vpc_security_group_rule.egress_rules](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_security_group_rule)              | resource    |
| [yandex_vpc_security_group_rule.ingress_rules_with_cidrs](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_security_group_rule)  | resource    |
| [yandex_vpc_security_group_rule.ingress_rules_with_sg_ids](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_security_group_rule) | resource    |
| [yandex_vpc_security_group_rule.ingress_self_rule](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_security_group_rule)         | resource    |
| [yandex_client_config.client](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/data-sources/client_config)                                     | data source |

## Inputs

| Name                                                                                                                  | Description                                                                                                                                                                                                                                                                                                                                                                                | Type          | Default | Required |
| --------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------- | ------- | :------: |
| <a name="input_egress_rules"></a> [egress\_rules](#input\_egress\_rules)                                              | SG egress rules with CIDRS.<br>  Example:<br><br>  egress\_rules = [<br>  {<br>    protocol       = "ANY"<br>    description    = "To the internet"<br>    v4\_cidr\_blocks = ["0.0.0.0/0"]<br>  },<br>]                                                                                                                                                                                   | `any`         | n/a     |   yes    |
| <a name="input_folder_id"></a> [folder\_id](#input\_folder\_id)                                                       | Folder-ID where the resources will be created                                                                                                                                                                                                                                                                                                                                              | `string`      | `null`  |    no    |
| <a name="input_ingress_rules_with_cidrs"></a> [ingress\_rules\_with\_cidrs](#input\_ingress\_rules\_with\_cidrs)      | SG rules with CIDRs as source.<br>  Example:<br><br>  ingress\_rules\_with\_cidrs = [<br>  {<br>    description    = "ssh"<br>    port           = 22<br>    protocol       = "ANY"<br>    v4\_cidr\_blocks = ["0.0.0.0/0"]<br>  },<br>  {<br>    description    = "ICMP"<br>    v4\_cidr\_blocks = ["0.0.0.0/0"]<br>    from\_port      = 0<br>    to\_port        = 65535<br>  },<br>  ] | `any`         | n/a     |   yes    |
| <a name="input_ingress_rules_with_sg_ids"></a> [ingress\_rules\_with\_sg\_ids](#input\_ingress\_rules\_with\_sg\_ids) | SG rules with other SG-id as source.<br>  Example:<br><br>  ingress\_rules\_with\_sg\_ids = [<br>  {<br>    protocol          = "ANY"<br>    description       = "Communication with web SG"<br>    security\_group\_id = "xxx222xxx"<br>  },<br>]                                                                                                                                         | `any`         | n/a     |   yes    |
| <a name="input_labels"></a> [labels](#input\_labels)                                                                  | A set of key/value label pairs to assign.                                                                                                                                                                                                                                                                                                                                                  | `map(string)` | `null`  |    no    |
| <a name="input_name"></a> [name](#input\_name)                                                                        | SG name                                                                                                                                                                                                                                                                                                                                                                                    | `string`      | n/a     |   yes    |
| <a name="input_self"></a> [self](#input\_self)                                                                        | Is SG allow communicate                                                                                                                                                                                                                                                                                                                                                                    | `bool`        | `true`  |    no    |
| <a name="input_self_from_port"></a> [self\_from\_port](#input\_self\_from\_port)                                      | allows communication within security group with port from                                                                                                                                                                                                                                                                                                                                  | `number`      | `null`  |    no    |
| <a name="input_self_port"></a> [self\_port](#input\_self\_port)                                                       | allows communication within security group with port                                                                                                                                                                                                                                                                                                                                       | `number`      | `null`  |    no    |
| <a name="input_self_protocol"></a> [self\_protocol](#input\_self\_protocol)                                           | allows communication within security group with protocol                                                                                                                                                                                                                                                                                                                                   | `string`      | `"ANY"` |    no    |
| <a name="input_self_to_port"></a> [self\_to\_port](#input\_self\_to\_port)                                            | allows communication within security group with port to                                                                                                                                                                                                                                                                                                                                    | `number`      | `null`  |    no    |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id)                                                                | Existing network\_id(vpc-id) where resource be created                                                                                                                                                                                                                                                                                                                                     | `string`      | `null`  |    no    |

## Outputs

| Name                                       | Description                  |
| ------------------------------------------ | ---------------------------- |
| <a name="output_id"></a> [id](#output\_id) | ID of created security group |
