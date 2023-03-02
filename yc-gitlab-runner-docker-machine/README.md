# gitlab-runner-docker-machine

Манифест [Terraform](https://www.terraform.io/) для динамического создания воркеров GitLab CI базе [GitLab Runner](https://docs.gitlab.com/runner/), [docker-machine](https://gitlab.com/gitlab-org/ci-cd/docker-machine) и драйвера для [Yandex Clouid](https://github.com/yandex-cloud/docker-machine-driver-yandex)

## Назначение

Позволяет по запросу от CI создавать временныe воркеры GitLab Runner для выполнения конвейеров CI. Предназначена для сборки и тестирования контейнеров `docker`, а также для других задач, где требуется среда исполнения `docker` (docker gitlab executor).

## Преимущества 

- Штатная функциональность GitLab Runner
- Не требуется кластер Kubernetes
- Необходима одна постоянная виртуальная машина c минимальными характеристиками: 2 cpu 50%, 2Gb памяти, 20Gb диск, временные воркеры создаются по требованию
- Динамически создаваемые воркеры позволяют эффективно использовать вычислительные ресурсы
- Короткое время жизни воркера позволяте использовать преимущества NRD дисков практически без риска потери данных
- За счет изоляции снижаются риски информационной безопасности при использовании привилегированного режима для контейнеров `docker:dind`
- Гибкое управление временем жизни воркеров с помощь расписания

## Принцип действия

GitLab Runner работает на постоянной виртуальной машине с минимальными характеристиками. При получении задания от GitLab CI, Runner создает виртуальную машину с заданными параметрами (4 cpu, 8 Gb, 93 Gb network-ssd-nonreplicated), устанавливает на нее сервис `docker` и запускает в нем выполнение задания. Одновременно может быть создано несколько виртуальных машин для параллельного выполнения нескольких заданий. После завершения задания GitLab Runner ожидает новые задания в течении 30 минут в рабочее время или 10 минут в остальное время. Если новых заданий в указанный период не поступает, временная виртуальная машина удаляется.  

## Испольование манифеста terraform

[Установите terraform подготовьте облако к работе](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart). 

Для применения манифеста необходимо уаказать 4 обязательных параметра: cloud_id, folder_id, gitlab_url, gitlab_registration_token. Например, через файл terraform.tfvars 

> Значения "по умолчанию" остальных параметров приведены в справке ниже

```
# terraform.tfvars
cloud_id = "b1gxxxxx"
folder_id = "b1gxxxxx"
gitlab_registration_token = "GRxxxxxxx-UAxxxxxxx"
gitlab_url = "https://xxxxxx.gitlab.yandexcloud.net/"

```
Выполните инициализацию terraform 
```
terraform init
```

Примените манифест
```
terraform apply
```

После успешного применения манифеста, через 40-60 секунд, в списе раннеров появится появиться новый раннер 

Замечания:
- Манифест создает файл конфигурации для GitLab Runner и постоянную ВМ. По умолчанию, ВМ создается с публичным адресом
- Финальная настройка ВМ производится скриптом /root/postinstall.sh. Скрипт и файл конфигурации доставляются на ВМ через user-data. Скрипт выполняет установку gitlab-runner, docker-machiche и docker-machine-yandex-driver
- Данные для регистрации GitLab Runner (URL и токен) передаются через [Yandex Lockbox](https://cloud.yandex.ru/docs/lockbox/). Регистрация в GitLab CI выполняется при старте сервиса gitlab-runner.
- Операции по созданию временных ВМ выполняются от сервисного аккаунта, привязанного к постоянной ВМ
- Группы безопасности открывают доступ к временным ВМ только с постоянной ВМ. 

## Требования к ПО

| Название | Версия |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |

## Провайдеры

| Название | Версия |
|------|---------|
| <a name="provider_yandex"></a> [yandex](#provider\_yandex) | 0.85.0 |

## Модули

| Название | Исх. код | Версия |
|------|--------|---------|
| <a name="module_network"></a> [network](#module\_network) | ./modules/network | n/a |

## Ресурсы

| Название | Тип |
|------|------|
| [yandex_compute_instance.gitlab_docker_machine](https://registry.tfpla.net/providers/yandex-cloud/yandex/latest/docs/resources/compute_instance) | resource |
| [yandex_iam_service_account.gitlab_docker_machine](https://registry.tfpla.net/providers/yandex-cloud/yandex/latest/docs/resources/iam_service_account) | resource |
| [yandex_kms_symmetric_key.gitlab_token_key](https://registry.tfpla.net/providers/yandex-cloud/yandex/latest/docs/resources/kms_symmetric_key) | resource |
| [yandex_kms_symmetric_key_iam_binding.gitlab_docker_machine_kms_roles](https://registry.tfpla.net/providers/yandex-cloud/yandex/latest/docs/resources/kms_symmetric_key_iam_binding) | resource |
| [yandex_lockbox_secret.gitlab_token](https://registry.tfpla.net/providers/yandex-cloud/yandex/latest/docs/resources/lockbox_secret) | resource |
| [yandex_lockbox_secret_version.gitlab_token_version](https://registry.tfpla.net/providers/yandex-cloud/yandex/latest/docs/resources/lockbox_secret_version) | resource |
| [yandex_resourcemanager_folder_iam_member.gitlab_docker_machine_roles](https://registry.tfpla.net/providers/yandex-cloud/yandex/latest/docs/resources/resourcemanager_folder_iam_member) | resource |
| [yandex_vpc_security_group.security_group_worker](https://registry.tfpla.net/providers/yandex-cloud/yandex/latest/docs/resources/vpc_security_group) | resource |
| [yandex_vpc_security_group.securtiy_group_master](https://registry.tfpla.net/providers/yandex-cloud/yandex/latest/docs/resources/vpc_security_group) | resource |
| [yandex_compute_image.ubuntu_lts](https://registry.tfpla.net/providers/yandex-cloud/yandex/latest/docs/data-sources/compute_image) | data source |

## Параметры

| Название | Описание | Тип | Значение по умолчанию | Обязательное |
|------|-------------|------|---------|:--------:|
| <a name="input_cloud_id"></a> [cloud\_id](#input\_cloud\_id) | cloud-id | `string` | n/a | yes |
| <a name="input_default_region"></a> [default\_region](#input\_default\_region) | Default Yandex Cloud region | `string` | `"ru-central1"` | no |
| <a name="input_default_zone"></a> [default\_zone](#input\_default\_zone) | Default availability zone | `string` | `"ru-central1-a"` | no |
| <a name="input_folder_id"></a> [folder\_id](#input\_folder\_id) | folder-id | `string` | n/a | yes |
| <a name="input_gitlab_registration_token"></a> [gitlab\_registration\_token](#input\_gitlab\_registration\_token) | gitlab registration token | `string` | n/a | yes |
| <a name="input_gitlab_url"></a> [gitlab\_url](#input\_gitlab\_url) | gitlab url | `string` | n/a | yes |
| <a name="input_gitlab_runner_tags"></a> [gitlab\_runner\_tags](#input\_gitlab\_runner\_tags) | gitlab runner tags | `string` | `""` | no |
| <a name="input_network_cidr"></a> [network\_cidr](#input\_network\_cidr) | network cidr | `string` | `"10.11.12.0/24"` | no |
| <a name="input_network_create"></a> [network\_create](#input\_network\_create) | create the network? | `bool` | `true` | no |
| <a name="input_network_description"></a> [network\_description](#input\_network\_description) | Network description | `string` | `"autocreated docker-machine network"` | no |
| <a name="input_network_id"></a> [network\_id](#input\_network\_id) | Existing network\_id(vpc-id) where resources will be created | `string` | `null` | no |
| <a name="input_network_name"></a> [network\_name](#input\_network\_name) | Network name | `string` | `"docker-machine"` | no |
| <a name="input_purpose"></a> [purpose](#input\_purpose) | Virtual machine purpose (prod, dev, stage, etc) | `string` | `"docker-machine"` | no |
| <a name="input_security_group_create"></a> [security\_group\_create](#input\_security\_group\_create) | create security group(s)? | `bool` | `true` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Existing subnet id | `string` | `null` | no |
| <a name="input_user_pubkey_filename"></a> [user\_pubkey\_filename](#input\_user\_pubkey\_filename) | ssh public key filename | `string` | `"~/.ssh/id_rsa.pub"` | no |
| <a name="input_username"></a> [username](#input\_username) | Initialzation username | `string` | `"ubuntu"` | no |
| <a name="input_worker_runners_limit"></a> [worker\_runners\_limit](#input\_worker\_runners\_limit) | Maximum number of parallel workers | `string` | `"10"` | no |
| <a name="input_worker_cores"></a> [worker\_cores](#input\_worker\_cores) | yandex-cores | `string` | `"4"` | no |
| <a name="input_worker_disk_size"></a> [worker\_disk\_size](#input\_worker\_disk\_size) | yandex-disk-size | `string` | `"93"` | no |
| <a name="input_worker_disk_type"></a> [worker\_disk\_type](#input\_worker\_disk\_type) | yandex-disk-type | `string` | `"network-ssd-nonreplicated"` | no |
| <a name="input_worker_image_family"></a> [worker\_image\_family](#input\_worker\_image\_family) | yandex-image-family | `string` | `"ubuntu-2204-lts"` | no |
| <a name="input_worker_memory"></a> [worker\_memory](#input\_worker\_memory) | yandex-memory | `string` | `"8"` | no |
| <a name="input_worker_platform_id"></a> [worker\_platform\_id](#input\_worker\_platform\_id) | yandex-platform-id | `string` | `"standard-v3"` | no |
| <a name="input_worker_preemptible"></a> [worker\_preemptible](#input\_worker\_preemptible) | yandex-preemptible | `bool` | `true` | no |
| <a name="input_worker_use_internal_ip"></a> [worker\_use\_internal\_ip](#input\_worker\_use\_internal\_ip) | yandex-use-internal-ip | `bool` | `true` | no |

## Результат

| Название | Описание |
|------|-------------|
| <a name="output_docker-machine"></a> [docker-machine](#output\_docker-machine) | ssh command for connection |
