# Установка Unified Agent для мониторинга метрик пода с помощью политики Kyverno

## Установить kyverno
Установите Kyverno из Kubernetes Marketplace или при помощи Helm-чарта:
[Инструкции по установке](https://cloud.yandex.ru/docs/managed-kubernetes/operations/applications/kyverno)

## Создание политики

Создайте файл `inject-unified-agent.yaml` со следующим содержимым, заменив `<FOLDER_ID>` на идентификатор Вашего каталога в Yandex Cloud:
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: inject-unified-agent
spec:
  rules:
  - name: inject-unified-agent
    match:
      resources:
        kinds:
        - Deployment
        - DaemonSet
        - StatefulSet
    mutate:
      patchStrategicMerge:
        metadata:
          annotations:
            (monitoring.yc.io/unified-agent-inject): "true"
        spec:
          template:
            spec:
              containers:
              - name: unified-agent
                image: cr.yandex/yc/unified-agent
                imagePullPolicy: IfNotPresent
                env:
                  - name: FOLDER_ID
                    value: <FOLDER_ID>
                  - name: SCRAPE_PORT
                    value: "{{request.object.metadata.annotations.\"monitoring.yc.io/scrape-port\"}}"
```

Создайте политику при помощи команды:
```bash
kubectl apply -f inject-unified-agent.yaml
```

## Создайте приложение
Отредактируйте аннотации существующего приложения, если оно производит экспорт метрик Prometheus, либо создайте тестовое приложение NGINX.

Создайте файл `nginx.yaml` со следующим содержимым:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  annotations:
    monitoring.yc.io/unified-agent-inject: "true"
    monitoring.yc.io/scrape-port: "8080"
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:1.15
```

Создайте приложение при помощи команды:
```bash
kubectl apply -f nginx.yaml
```

Убедитесь, что под приложения содержит сайдкар с контейнером `unified-agent`, который находится в состоянии `Running`:
```bash
kubectl describe pod nginx-5c4cd884f8-mtzxz
```

![](./img/img-01.png)

# Результат
Убедитесь, что метрики поступают в [Yandex Monitoring](https://cloud.yandex.ru/services/monitoring).
На [главной странице](https://monitoring.cloud.yandex.ru/) сервиса Yandex Monitoring перейдите в раздел **Обзор метрик**.

В строке запроса выберите:
* каталог, в который собираются метрики;
* значение метки `service=custom`;
* значение метки `host` с именем пода Kubernetes.

```
"*"{folderId="<FOLDER_ID>", service="custom", host="nginx-5c4cd884f8-mtzxz"}
```

![](./img/img-02.png)
