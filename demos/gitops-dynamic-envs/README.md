# Практические материалы к вебинару "Поднимаем динамические стенды с помощью GitOps"

## Пререквизиты

- bash
- [cli](https://cloud.yandex.ru/docs/cli/operations/install-cli), инициированный в профиле default а вашего пользователя( он должен быть admin или editor на уровне облака)


## Часть 1 - создание инфструктурного стенда 

Следуйте [данной инструкции](https://github.com/yandex-cloud/yc-architect-solution-library/blob/main/demos/gitops-argo-crossplane/01-mk8s-gitlab/README.md)

## Часть 2 - установка argocd и Crossplane

```
$ cd ./02-argocd-crossplane/
```

И изучаем readme [данного раздела](./02-argocd-crossplane/)

## Часть 3 - деплой динамических окружений

```
$ cd ./03-dynamic-envs/
```

И изучаем readme [данного раздела](./03-dynamic-envs/)
