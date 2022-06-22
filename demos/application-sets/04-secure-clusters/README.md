# Secure clusters

## Создание инфраструктуры 


* Склонируйте созданный на предыдущем шаге репозиторий `infrastructure` на локальную машину 

```bash
git clone git@<gitlab host>.gitlab.yandexcloud.net:demo/infrastructure.git
```

* Скопируйте в локальный репозиторий infrastructure содержимое каталога [infrastructure](../projects/infrastructure)
* Отредактиуйте файл параметров деплоя инфраструктуры [infra/dev/values.yaml](../projects/infrastructure/infra/dev/values.yaml): необходимо установить актуальный значения в полях cloudId и folderId; сами значения можно получить выполнив команду `yc config list`


Пример `values.yaml`

```bash
cloudId: "b1gxxxxxx"
folderId: "b1gxxxxxx"

providerConfigName: "default"

projectName: "demo"
projectSuffix: "dev"

clusterType: "zonal"
clusterVersion: "1.21"
clusterReleaseChannel: "RAPID"

securityGroupsEnabled: true
secretEncryptionEnabled: truell
```

После редактирования необходимо закоммитить изменения в master ветку репозитория и выполнить git push. 

## Создание ApplicationSet


Отредактируйте [kubernetes-clusters.yaml](../projects/infrastructure/application-sets/secure-clusters/kubernetes-clusters.yaml)

Важные замечания:

* ApplicationSet это CDR объект ArgoCD, который описывает правила создания объектов Application. ApplicationSet существует в пространстве имен (namespace) и должен создаваться в том же простанстве имен, что и исталляция ArgoCD. Обратите внимение на поле namespace
* В поле repoURL (в двух местах) должен быть указан объект репозитория, который необходимо [предварительно создать в ArgoCD](../02-argocd/README.md#добавление-репозитория) (шаг "Добавление репозитория"). __ВАЖНО!__ Обратите внимание: это не просто url репозитория, а именно объект ArgoCD. 


```bash
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: kubernetes-clusters
  namespace: argocd # insert your argocd namespace
spec:
  generators:
  - git:
      repoURL: https://<gitlab host>.gitlab.yandexcloud.net/demo/infrastructure.git # insert your arogcd repo  address
      revision: HEAD
      directories:
      - path: infra/*
  template:
    metadata:
      name: '{{path.basenameNormalized}}'
    spec:
      project: default
      source:
        helm:
          valueFiles:
          - '../../{{path}}/values.yaml'
        repoURL: https://<gitlab host>.gitlab.yandexcloud.net/demo/infrastructure.git # insert your arogcd repo  address
        targetRevision: HEAD
        path: "crossplane-charts/k8s-cluster"
      destination:
        server: https://kubernetes.default.svc # default argocd cluster is used, other cluster can be specified as well
        namespace: clusters
      syncPolicy:
        automated:
          selfHeal: true
        syncOptions:
        - CreateNamespace=true
```

Создайте ApplicationSet

```kubectl apply kubernetes-clusters.yaml```

После это шага начнется создание ифраструктуры

## Добавление кластера Kubernetes в ArgoCD


Подключитесь консольным клиентом argocd к серверу argocd любым доступным способом, например c помощью port-forward 

```bash
kubectl -n argocd port-forward svc/argo-cd-argocd-server  8443:443 &

argocd login 127.0.0.1:8443 --name admin
```

Пароль для подключения к argocd можно извлечь из секрета

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
```

Дождитесь, когда будет создан dev кластер kubernetes. Получите доступ к нему через вэб-интерфейс консоли (кнопка "подключиться" в конексте кластера) или через консольную утилиту управления (для --folder-id надо указать folderId из шага "Создание инфраструктуры")

```bash
yc managed-kubernetes cluster get-credentials --name kube-demo-dev --folder-id b1gxxxxxx
```


Добавьте кластер кубернетес в argocd  

```bash
argocd cluster add yc-kube-demo-dev
```

Через некоторое време убедитесь, что в новом кластере развернут kyverno
