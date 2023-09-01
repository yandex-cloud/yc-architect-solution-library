# Автоматизированное управление инфраструктурой через терраформ в GitLab

## Условия использования:
* Сервисный аккаунт в Yandex Cloud (с ролями, которые позволяют создавать или управлять нужными ресурсами в облаке, а также с необходимыми правами - `storage.uploader`, `container-registry.images.puller`)
* Минимальный [**Managed-GitLab инстанс**](https://cloud.yandex.ru/docs/managed-gitlab/operations/instance/instance-create) c [**настроенными доступом**](https://cloud.yandex.ru/docs/managed-gitlab/operations/connect) для подключения
* [**GitLab Runner**](https://docs.gitlab.com/ee/tutorials/create_register_first_runner/#create-and-register-a-project-runner) , который может быть, например:
1. [**облачной ВМ**](https://docs.gitlab.com/runner/register/#linux) (с внешним ip-адресом) и (предустановленной) средой выполнения (executor) [**Docker**](https://docs.gitlab.com/runner/executors/docker.html)
2. managed-cluster'ом [**Kubernetes**](https://cloud.yandex.ru/docs/managed-kubernetes/operations/applications/gitlab-runner). 
* [**Бакет**](https://cloud.yandex.ru/docs/storage/operations/buckets/create) в облачном хранилище Yandex Cloud (здесь будет храниться файл состояния вашей инфраструктуры `<name>.tfstate`)
* [**Container Registry**](https://cloud.yandex.ru/docs/container-registry/operations/registry/registry-create) в Yandex Cloud
* Предустановленный Docker на локальном ПК (или виртуальной машине) для сборки образа контейнера

## Описание
1. Создание образа с терраформ.
В папку c `Dockerfile`, потребуется распаковать и положить предварительно [**скачанный бинарник terraform**](https://developer.hashicorp.com/terraform/downloads) нужной версии, для `Linux` и архитектуры `AMD64`.
Далее логинимcя в Container Registry:
```
docker login --username iam --password $(yc iam create-token) cr.yandex
```
После чего создаем образ, добавляем нужный тег и загружаем наш реестр (`container-registry-id` меняем на id нашего реестра):
```
docker build -t gitlabtf:latest .
docker tag gitlabtf:latest cr.yandex/<container-registry-id>/gitlabtf:latest
docker push cr.yandex/<container-registry-id>/gitlabtf:latest
```

2. [**Настройте**](https://cloud.yandex.ru/docs/managed-gitlab/quickstart#configure-mgl) Managed-Gitlab инстанс и создайте новый проект (мы рекомендуем [**создавать непубличные проекты**](https://docs.gitlab.com/ee/user/public_access.html)), добавив туда все файлы из данной папки (или просто [**импортировав**](https://docs.gitlab.com/ee/user/project/import/github.html#import-your-github-repository-into-gitlab) , предварительно форкнув его на GitHub) и [**добавьте**](https://docs.gitlab.com/ee/tutorials/create_register_first_runner/#create-and-register-a-project-runner) (предварительно созданный) GitLab-Runner (см. `Условия использования` > `GitLab Runner`).

3. Во вновь созданном (импортированном) проекте, потребуется изменить некоторые файлы, а также [**создать переменные окружения**](https://docs.gitlab.com/ee/ci/variables/#define-a-cicd-variable-in-the-ui) и значения для них:
    1. В файле `templates/Base.latest.gitlab-ci.yml` потребуется изменить 3-ю строку (значение `image`), указать id вашего Container Registry в ссылке на образ.
    2. Потребуется [**создать авторизованный ключ для сервисного аккаунта**](https://cloud.yandex.ru/docs/iam/operations/authorized-key/create) и содержимое ключа добавить при [**создании переменной**](https://docs.gitlab.com/ee/ci/variables/#define-a-cicd-variable-in-the-ui) `TF_VAR_sauth` для проекта. (поля и чекбоксы при создании: `type: ENV_VAR`, `Protect variable`,`Expand variable reference `)
    3. Потребуется создать [**статический ключ доступа для сервисного аккаунта**](https://cloud.yandex.ru/docs/iam/operations/sa/create-access-key) и [**содержимое ключа**](https://cloud.yandex.ru/docs/iam/concepts/authorization/access-key) добавить в переменные, а именно: `key_id` в переменную `TF_VAR_s3key`, `secret` в переменную `TF_VAR_s3secret`. (поля и чекбоксы при создании: `type: ENV_VAR`, `Protect variable`,`Expand variable reference `)
    4. Также, потребуется задать [**переменную**](https://docs.gitlab.com/ee/ci/docker/using_docker_images.html#access-an-image-from-a-private-container-registry) `DOCKER_AUTH_CONFIG`, для авторизации Runner'a в Container Registry и возможности созданный ранее образ.
    Самый простой способ задать данную переменную, это [**авторизоваться в Container Registry с помощью ранее созданного авторизованного ключа для сервисного аккаунта**](https://cloud.yandex.ru/docs/container-registry/operations/authentication#sa). После чего скопировать авторизованные данные из файла по пути`$HOME/.docker/config.json` и вставить в данные переменной.
    **!Осторожно!** В файле могу быть данные для авторизации в других регистри, значение переменной должно выглядеть похоже на это:
    ```
{
        "auths": {
                "cr.yandex": {
                        "auth": "aWFt......dw=="
                },

        }
}
    ```
    5. Также, в файле `variables.tf`, потребуется задать значение переменных `default` в следующих сниппетах (указав id ваших каталога и облака соответственно):
    ```
    variable "folder" {
    default = ""
}

   variable "cloud" {
    default = ""
}
    ```
    6. В файле `main.tf`, в следующем сниппете, следует указать значения для ключей `bucket` (имя вашего бакета) и `key` (путь до файла `<name>.tfstate`, где будет храниться информация о состоянии вашей инфраструктуры):
    ```
    backend "s3" {
      endpoint   = "storage.yandexcloud.net"
      bucket     = "<bucket_name>"
      region     = "ru-central1"
      key        = "<path/to/terraform.tfstate>"
      access_key = var.s3key
      secret_key = var.s3secret

      skip_region_validation      = true
      skip_credentials_validation = true
  }
    ```
## Дополнительно
При каждом коммите, пайплайн запускает 3 jobs: первая - это валидация манифестов (validate), вторая - это построение плана действий (build), третья - это применение действий (deploy (destroy)).
В силу причин безопасности, третий "этап" не выполняется автоматически, так как может нарушить целостность инфраструктуры, например, удалить необходимые ресурсы, если это не планировалось.
Следует убедиться по логам второго "этапа" (build), соответствуют ли планируемые изменения желаемому состоянию инфраструктуры, если да, то запустить вручную третий "этап".

Файл `network.tf`, является примером, для демострации успешного создания тестовых ресурсов VPC в виде сети с именем - `testing`, и подсети c именем `test_sub`. 