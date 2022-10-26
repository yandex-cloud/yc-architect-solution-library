# Crossplane

## Установка Crossplane

Установите [crossplane](https://crossplane.io/) из Marketplace.

* Для этого сначала нужно подготовить сервисный аккаунт с нужными правами
для того чтобы Crossplane имел возможность работать с объектами облака.

> Не забудьте поменять <FOLDER NAME> и <CLOUD NAME> на ваше реальное имя фолдера и облака

```bash
yc iam service-account create \
  --name crossplane-demo \
  --folder-name <FOLDER NAME>

yc resource-manager cloud add-access-binding \
  <CLOUD NAME> \
  --role admin \
  --service-account-name crossplane-demo
```

* Далее перейдите в веб-консоль, выберите созданный кластер Kubernetes
и перейдите в раздел `Marketplace`

* Выберите продукт `Crossplane с поддержкой Yandex Cloud`

* Нажмите кнопку `Использовать`.

* Введите необходимые параметры.
В разделе `Ключ сервисной учетной записи` нажмите создать новый и выберите
сервисный аккаунт созданный на предыдущем шаге

* Нажмите кнопку `Установить`

## Создание инфраструктуры с помощью Crossplane

* Перейдите в директорию `03-crossplane/manifests` в данном репозитории, вставьте значение <FOLDER_ID> Вашего целевого каталога в манифесты.

* Примените манифесты в кластер:

```bash
kubectl apply -f .
```

* Проверьте статусы созданных объектов

```bash
kubectl get network
kubectl get subnet
kubectl get instance
```

## Удаление окружения

Для удаления созданных ресурсов перейдите в директорию `03-crossplane/manifests`
и выполните

```bash
kubectl delete -f .
```
