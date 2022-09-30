## Практическое задание #4. Работа с Crossplane

Список задач практического задания:
* 4.1 [Установка Crossplane в кластер Kubernetes](#h4-1)
* 4.3 [Развёртывание ВМ с веб-сервером](#h4-2)
* 4.4 [Удаление ВМ](#h4-3)

### 4.1 Установка Crossplane в кластер Kubernetes <a id="h4-1"/></a>

Развернуть Crossplane с помощью Helm:
```bash
NS=crossplane-system
kubectl create namespace $NS
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
helm install crossplane --namespace $NS crossplane-stable/crossplane

# Install Crossplane CLI
curl -sL https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh | sh
sudo mv kubectl-crossplane $(dirname $(which kubectl))
```

Проверить состояние Crossplane после развёртывания:
```bash
helm list -n $NS
kubectl get all -n $NS
```

Установить Crossplane Provider:
```bash
kubectl crossplane install provider cr.yandex/crp0kch415f0lke009ft/crossplane/provider-jet-yc:v0.1.37
```

Создать ключи для работы Crossplane Provider:
```bash
SA_NAME=webinar-sa
SA_ID=$(yc iam service-account list --format=json | jq -r '.[] | select(.name == ('\"$SA_NAME\"')) | .id')
yc iam key create --service-account-id $SA_ID --output key.json
```

Создать в кластере Secret для Crossplane Provider:
```bash
kubectl create secret generic yc-creds -n $NS --from-file=credentials=./key.json
```

Создать в кластере Crossplane ProviderConfig:
```bash
cd ~/labs/lab-04-crossplane/
kubectl apply -f providerconfig.yml
```

### 4.2 Развёртывание ВМ с веб-сервером <a id="h4-2"/></a>

Подготовить входные данные для развёртывания ВМ:
```bash
export ZONE_ID="ru-central1-b"
export VM_NAME="crossplane-vm"
export SUBNET_NAME=$NET_NAME-$ZONE_ID
export NET_NAME=$(yc vpc network list --limit=1 --format=json | jq -r .[0].name)
export SUBNET_ID=$(yc vpc subnet get --name=$SUBNET_NAME --format=json | jq -r .id)
export NET_ID=$(yc vpc subnet get $SUBNET_ID --format=json | jq -r .network_id)
export SUBNET_PREFIX=$(yc vpc subnet get $SUBNET_ID --format=json | jq -r .v4_cidr_blocks[0])
export FOLDER_ID=$(yc config get folder-id)
export IMAGE_ID=$(yc compute image get --folder-id standard-images --name=lemp-v20220606 --format=json | jq -r .id)
```

Заполнить шаблон манифеста crossplane для создания ВМ нужными значениями из исходных данных:
```bash
envsubst < vm-instance.tpl > vm-instance.yml
```

Проверить полученный манифест для создания ВМ перед его применением:
```
cat vm-instance.yml
```

Создать ВМ с веб-сервером из подготовленного манифеста ВМ:
```bash
kubectl apply -f vm-instance.yml
```

Проверить состояния созданных в кластере Kubernetes объектов под управлением Crossplane:
```bash
kubectl get network
kubectl get subnet
kubectl get instance
yc compute instance list
```

Проверить работоспособность развёрнутой ВМ:
```bash
LEMP_IP=$(yc compute instance get --name=$VM_NAME --format=json | jq -r .network_interfaces[0].primary_v4_address.address)

ping -c 3 $LEMP_IP
curl http://$LEMP_IP
```

### 4.3 Удаление ВМ с веб-сервером <a id="h4-3"/></a>

Удалить ВМ с помощью Crossplane:
```bash
kubectl delete instance $VM_NAME
```

Убедиться, что ВМ удалена
```bash
kubectl get instance
yc compute instance list
```

`Поздравляем! Вы успешно справились с заданием!`

### [ << задание 3 ](../lab-03-terraform/README.md) || [задание 5 >>](../lab-05-pulumi/README.md)
### [ << оглавление ](../README.md)
