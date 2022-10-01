## Практическое задание #2. Работа с Yandex Cloud CLI (yc)

Список задач практического задания:
* 2.1 [Клонирование репозитория практикума на ВМ](#h2-1)
* 2.2 [Настройка профиля YC CLI](#h2-2)
* 2.3 [Просмотр облачных ресурсов - подсети, ВМ](#h2-3)
* 2.4 [Создание ВМ с веб-сервером](#h2-4)
* 2.5 [Тестирование работы веб-сервера](#h2-5)
* 2.6 [Удаление ВМ с веб-сервером](#h2-6)

### 2.1 Клонирование репозитория практикума на ВМ<a id="h2-1"/></a>
```bash
mkdir labs
cd labs
REPO=yc-architect-solution-library
git clone https://github.com/yandex-cloud/$REPO.git
cp -R $REPO/demos/yc-infra-management/* .
rm -rf $REPO
unset REPO
```

### 2.2 Настройка профиля YC CLI <a id="h2-2"/></a>

`Важно! Для успешного выполнения дальнейших шагов необходимо успешное создание ВМ с привязанным SA в предыдущем практическом задании!`

Получаем идентификатор ВМ через [сервис метаданных](https://cloud.yandex.ru/docs/compute/concepts/vm-metadata):
```bash
VM_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
```

Получаем данные cloud_id и folder_id с помощью yc:
```bash
FOLDER_ID=$(yc compute instance get $VM_ID --format=json | jq -r .folder_id)
CLOUD_ID=$(yc resource folder get $FOLDER_ID --format=json | jq -r .cloud_id)
```

Создаём профиль с именем `default` для инструмента `yc`:
```bash
yc config profile create default
yc config set cloud-id $CLOUD_ID
yc config set folder-id $FOLDER_ID
unset CLOUD_ID FOLDER_ID VM_ID
```

Сохраняем нужные значения переменных в файл параметров окружения:
```bash
cat << EOF >> ~/.bashrc
# YC
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)
export YC_TOKEN=\$(yc iam create-token)
EOF

source $HOME/.bashrc
```

Убедиться, что `yc профиль` создан и активирован:
```bash
yc config profile list
yc config list
```

### 2.3 Просмотр облачных ресурсов - подсети, ВМ <a id="h2-3"/></a>

Получить список облачных подсетей:
```bash
yc vpc subnet list
```

Получить список виртуальных машин:
```bash
yc compute instance list
```

Получить детальную информацию о ВМ с именем `infra-vm`:
```bash
yc compute instance get --name=infra-vm
```

Получить детальную информацию о ВМ с именем `infra-vm` в формате JSON:
```bash
yc compute instance get --name=infra-vm --format=json | jq
```

### 2.4 Создание ВМ с веб-сервером <a id="h2-4"/></a>

В данной части будет создаваться ВМ на базе [LEMP стека](https://lempstack.com/).

Создать пару SSH ключей, для аутентификации на ВМ
```bash
ssh-keygen -t rsa -b 2048 -f $HOME/.ssh/id_rsa -q -N ""
```

Подготовить входные данные для создания ВМ с веб-сервером
```bash
YC_ZONE="ru-central1-b"
YC_NET=$(yc vpc network list --limit=1 --format=json | jq -r .[0].name)
YC_SUBNET=$YC_NET-$YC_ZONE
```

Создать ВМ с веб-сервером
```bash
yc compute instance create --name=lemp-vm --hostname=lemp-vm\
  --zone $YC_ZONE \
  --create-boot-disk image-folder-id=standard-images,image-family=lemp \
  --cores=2 --memory=4G --core-fraction=100 \
  --network-interface subnet-name=$YC_SUBNET,ipv4-address=auto \
  --ssh-key ~/.ssh/id_rsa.pub
```

### 2.5 Тестирование работы веб-сервера <a id="h2-5"/></a>

Убедиться в том, что ВМ с веб-сервером создана
```bash
yc compute instance list
```
Сохранить IP адрес созданной ВМ в переменной окружения
```bash
LEMP_IP=$(yc compute instance get --name=lemp-vm --format=json | jq -r .network_interfaces[0].primary_v4_address.address)
```

Проверить сетевую доступность ВМ
```bash
ping -c 3 $LEMP_IP
```

Проверить работу веб-сервера на ВМ
```bash
curl http://$LEMP_IP
```

Подключиться к ВМ c веб-сервером по SSH
```bash
ssh yc-user@$LEMP_IP
exit
```

### 2.6 Удаление ВМ с веб-сервером <a id="h2-6"/></a>

Удалить ВМ с веб-сервером:
```bash
yc compute instance delete --name=lemp-vm
```

Убедиться, что ВМ успешно удалилась:
```bash
yc compute instance list
```

`Поздравляем! Вы успешно справились с заданием!`

### [ << задание 1 ](../lab-01-ui/README.md) || [задание 3 >>](../lab-03-terraform/README.md)
### [ << оглавление ](../README.md)
