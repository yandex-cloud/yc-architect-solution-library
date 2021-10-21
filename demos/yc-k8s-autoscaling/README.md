# Демонстрация автомасштабирования в Yandex.Cloud Managed Service for Kubernetes
Данный сцерарий демонстрирует функционал автомасштабирования средствами **Horizontal Pod Autoscaler** и **Cluster Autoscaler**. 

**Horizontal Pod Autoscaler** автоматически масштабирует количество **Pods** в **deployment**, **replica set** или **stateful set** на основе наблюдаемой загрузки CPU или RAM средствами  **metrics server**
(или, на основе пользовательских метрик, некоторых других метрик, предоставляемых приложением).

![](https://d33wubrfki0l68.cloudfront.net/4fe1ef7265a93f5f564bd3fbb0269ebd10b73b4e/1775d/images/docs/horizontal-pod-autoscaler.svg)
**Cluster Autoscaler**-это инструмент, который автоматически изменяет количество *worker nodes* кластера Kubernetes при выполнении одного из следующих условий:

- есть **Pods**, которые не удалось запустить в кластере из-за нехватки ресурсов.
- в кластере есть *worker nodes*, которые были недостаточно утилизированны в течение длительного периода времени, и их **Pods** могут быть размещены на других существующих узлах.


Стенд состоит из сети *Yandex Virtual Private Cloud* с  подсетями в трех зонах доступности (**AZ**), регионального кластера *Managed Service for Kubernetes* и  3-х *Node Group* в разных **AZ** c включенным **Автоматическим масштабированием**.

В данной демонстрации рассмотрим два сценария:
- масштабирование от утилизации **CPU** подов использую встроенный **Metric Server**.
- масштабирование от **RPS** на ingress использую **Prometheus-adapter**

## Требования
- Terraform ~>0.14
- YC cli
- Helm 3
- bash
- wget 
- watch

### Настройка Yandex.Cloud

- Установите [YC cli](https://cloud.yandex.com/docs/cli/quickstart)
- Настройте авторизацию в YC для Terraform
```
export YC_TOKEN=$(yc iam create-token)
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)
``` 
## Quick start

Создадим кластер *Managed Kubernetes*

```
terraform init
terraform apply
```
Добавим учетных данных в конфигурационный файл kubectl. Необходимо указать имя или id кластера

```
yc managed-kubernetes cluster get-credentials demo --external
```
### Масштабирование от утилизации **CPU**

Создадим *Deployment*, *service(LoadBalanсer)* и *HPA* для нашего тестового приложения

```
kubectl apply -f k8s_autoscale-CPU.yaml
```

Запустим в отдельном окне отслеживание интересующих компонентов кластера Kubernetes

```
watch kubectl get pod,svc,hpa,nodes -o wide
```
Посылаем *wget* по внешнему IP адресу балансировщика для имитации рабочей нагрузки.

```bash
URL=$(kubectl get service nginx -o json| jq -r '.status.loadBalancer.ingress[0].ip')
while true; do wget -q -O- http://$URL; done     
#где $URL внешней IP адрес service
```
Наблюдаем увеличение сначала *Pods* в *Deployment* "nginx", а затем и добавление узлов в *Kubernetes Node Groups* в разных зонах доступности.

Завершаем цикл имитации рабочей нагрузки и наблюдаем удаление реплик *Deployment* без нагрузки.

Через **7-10** минут кластер Kubernetes начнет удалять неутилизированные узлы.

Удалим созданные объекты Kubernetes

```
kubectl delete -f k8s_autoscale-CPU.yaml

```

### Масштабирование от утилизации **RPS**

Дополнительные компоненты устанавливаются с помощью пакетного менеджера **Helm**

Добавим репозитории **Helm**

```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```
Установим **Nginx ingress controller** с включенным представлением metrics

```
helm upgrade --install rps ingress-nginx/ingress-nginx --values values-ingr.yaml
```
Ingress-controller отдает в Prometheus метрику с общим количеством запросов, а не за промежуток времени. В то же время HPA не умеет работать с функциями для обработки метрик Prometheus, поэтому нам необходимо дописать в Prometheus `recording rule` для получения нужной нам метрики.

Для этого в значения Helm values для Prometheus добавлено правило:

```yaml
rules:
  groups:
    - name: Ingress
      rules:
        - record: nginx_ingress_controller_requests_per_second
          expr: rate(nginx_ingress_controller_requests[2m])
```
Установим **Prometheus** 

```
helm upgrade --install prometheus prometheus-community/prometheus --values values-prom.yaml
```
Установим **Prometheus adapter**, который необходим для доступа к метрикам Prometheus через kube-api. В файле values-prom-ad указано, по какому адресу и порту доступен Prometheus, и правило для метрик `nginx_ingress`
```
helm upgrade --install prometheus-adapter prometheus-community/prometheus-adapter --values values-prom-ad.yaml
```
Создадим *Deployment*, *service* , *ingress* и *HPA* для нашего второго тестового приложения

```
kubectl apply -f k8s_autoscale-RPS.yaml
```

После создания в Prometheus появится новая метрика с именем `nginx_ingress_controller_requests_per_second`.

Проверяем, что метрика `nginx_ingress_controller_requests_per_second` доступна через kube-api.

Prometheus **начинает** считать данную метрику только после прохождения трафика через Ingress. Поэтому выполним несколько тестовых запросов, повторив 2-3 раза команду:

```bash
URL=$(kubectl get service rps-ingress-nginx-controller -o json| jq -r '.status.loadBalancer.ingress[0].ip')
curl -H "Host: nginx.example.com" http://$URL
#где $URL внешней IP адрес service "rps-ingress-nginx-controller"
```
Далее выполняем
```
kubectl get --raw /apis/custom.metrics.k8s.io/v1beta1 |jq .| grep ingresses.networking.k8s.io/nginx_ingress_controller_requests_per_second
       

```
Должны получить в течение пары минут следующий результат: `"name": "ingresses.networking.k8s.io/nginx_ingress_controller_requests_per_second",`

### Проверка результата

Запустим в отдельном окне отслеживание интересующих компонентов кластера Kubernetes

```
watch kubectl get pod,svc,hpa,nodes -o wide
```
Обратите внимание, что при выполнении `watch kubectl get pod,svc,hpa,nodes -o wide` вы всегда будете видеть в поле `TARGETS 0/0` для **HPA nginx** - это баг. Если посмотреть в `kubectl describe hpa nginx`, то там можно увидеть правильное значение.

В посылаем *curl* по внешнему IP адресу service "rps-ingress-nginx-controller" для имитации рабочей нагрузки.

```bash
URL=$(kubectl get service rps-ingress-nginx-controller -o json| jq -r '.status.loadBalancer.ingress[0].ip')
while true; do curl -H "Host: nginx.example.com" http://$URL; done
#где $URL внешней IP адрес service "rps-ingress-nginx-controller"
```


Через несколько минут наблюдаем увеличение сначала *Pods* в *Deployment* "nginx", а затем и добавление узлов в *Kubernetes Node Groups* в разных зонах доступности.

Завершаем цикл имитации рабочей нагрузки и наблюдаем удаление реплик *Deployment* без нагрузки.

Через **7-10** минут кластер Kubernetes начнет удалять неутилизированные узлы.

### Удаляем тестовый стенд
```
terraform destroy
```
