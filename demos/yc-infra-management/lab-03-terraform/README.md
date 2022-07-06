## Практическое задание #3. Работа с Terraform

Список задач практического задания:
* 3.1 [Развёртывание кластера Managed Service for Kubernetes](#h3-1)
* 3.2 [Подключение к кластеру Kubernetes и проверка его состония](#h3-2)

### 3.1 Развёртывание кластера Managed Service for Kubernetes  <a id="h3-1"/></a>

В процессе выполнения будут развёрнуты слеудующие облачные ресурсы: 
* зональный кластер Kubernetes с одним `master node`
* одна группа узлов c одним `worker node` в группе

Подготовка входных данных для развёртывания кластера Kubernetes:
```bash
cd ~/labs/lab-03-terraform
cp /usr/local/etc/terraform.rc ~/.terraformrc
```

`ВАЖНО!` Заменить нули в значении переменной ниже на цифры из логина, предоставленого для аутентификации в облаке `SA_NAME=user-000-sa` и выполнить команду по созданию переменной `SA_NAME`.

```bash
SA_NAME=user-000-sa
```

```bash
ZONE_ID="ru-central1-b"
NET_NAME=$(yc vpc network list --format=json | jq -r .[0].name)
SUBNET_NAME=$NET_NAME-$ZONE_ID

export TF_VAR_sa_id=$(yc iam service-account get --name=$SA_NAME --format=json | jq -r .id)
export TF_VAR_subnet_id=$(yc vpc subnet get --name=$SUBNET_NAME --format=json | jq -r .id)
export TF_VAR_net_id=$(yc vpc subnet get $TF_VAR_subnet_id --format=json | jq -r .network_id)
export TF_VAR_zone_id=$ZONE_ID
```

Запустить развёртывание кластера Kubernetes

Инициализировать Terraform
```bash
terraform init
```

Посмотреть план выполнения Terraform
```bash
terraform plan
```

Выполнить (применить) план Terraform
```
terraform apply
```
Enter a value: `yes`

`Время развёртывания кластера и группы узлов занимает примерно 10-12 минут.`

`Документация:`
* [YC Terraform provider. Кластер Kubernetes](https://registry.tfpla.net/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_cluster)
* [YC Terraform provider. Группа узлов кластера Kubernetes](https://registry.tfpla.net/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_node_group)
* [Создание кластера Kubernetes](https://cloud.yandex.ru/docs/managed-kubernetes/operations/kubernetes-cluster/kubernetes-cluster-create)


### 3.2 Подключение к кластеру Kubernetes и проверка его состояния <a id="h3-2"/></a>

Проверить состояние кластера и группы узлов
```bash
yc k8s cluster list
yc k8s node-group list
```

Получить данные для конфигурации kubectl
```bash
yc k8s cluster get-credentials --name=k8s --internal
```

Проверить состояние кластера с помощью kubectl
```bash
kubectl cluster-info --kubeconfig /home/admin/.kube/config
```

Настроить autocomplete для kubectl
```bash
cat << EOF >> $HOME/.bashrc
# kubectl
source <(kubectl completion bash)
alias k=kubectl
complete -o default -F __start_kubectl k
EOF
source $HOME/.bashrc
```

Проверить состояние узлов кластера Kubernetes
```bash
kubectl get nodes
k get -A pods
k get ns
```

Проверить работу kubectl autocomplete.

Написать начало команды `k get apise` в командной строке и далее нажать `Tab`.
Строка должна расшриться до "k get apiservices.apiregistration.k8s.io" после чего нажать `Enter` и выполнить команду.


`Поздравляем! Вы успешно справились с заданием!`

### [ << задание 2 ](../lab-02-yc/README.md) || [задание 4 >>](../lab-04-crossplane/README.md)
### [ << оглавление ](../README.md)
