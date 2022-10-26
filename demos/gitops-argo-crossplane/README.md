# Практические материалы к вебинару "Внедряем Gitops практики в Yandex Cloud при помощи Kubernetes"

## Пререквизиты

- bash
- [cli](https://cloud.yandex.ru/docs/cli/operations/install-cli), инициированный в профиле default а вашего пользователя( он должен быть admin или editor на уровне облака)


## Часть 1 - создание инфструктурного стенда 

```
$ cd ./01-mk8s-gitlab
```

И изучаем readme [данного раздела](./01-mk8s-gitlab)

## Часть 2 - установка argocd

```
$ cd ./02-argocd/
```

И изучаем readme [данного раздела](./02-argocd/)

## Часть 3 - установка сrossplane

```
$ cd ./03-crossplane/
```

И изучаем readme [данного раздела](./03-crossplane/)

## Часть 4 - создание preprod кластера из helm chart при помощи gitlab, crossplane, argocd

```
$ cd ./04-preprod-cluster/
```

И изучаем readme [данного раздела](./04-preprod-cluster)
