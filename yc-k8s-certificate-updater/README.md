# DaemonSet для обновления сертификатов на нодах Managed K8s

## Описание 
DaemonSet будет выполнять следующее: 

1. При помощи bash скрипта постояннo проверять наличие нужных CA сертификатов на нодах.
2. В случае, если их нет, копировать их из секрета и обновлять сертификаты.
3. Перезагружать containerd и dockerd.

DaemonSet работает с нодами, использующими Docker runtime и Containerd runtime.

## Как запустить в общем случае

1) Создать namespace для работы daemonSet-а в целях изоляции его работы:
```
kubectl apply -f certificate-updater-ns.yaml
```
2) Создать простой secret с несколькими файлами внутри при помощи kubectl с указанием нескольких источников в рамках ранее созданного namespace:
```
kubectl create secret generic crt --from-file=num1.crt --from-file=num2.crt --from-file=num3.crt --from-file=num4.crt --from-file=num5.crt --namespace="certificate-updater"
```

Важно, что daemonSet ссылается на сертификат с именем crt.

3) Создать daemonSet:
```
kubectl apply -f certificate-updater-ds.yaml
```
Далее можно отслеживать состояние daemonSet-а: в случае когда произойдет обновление сертификатов, то перезагрузятся процессы dockerd и containerd.


### Обновление сертификатов

При помощи: 

```kubectl get secret crt -o yaml```

Мы можем получить практически готовую для переиспользования конфигурацию. Для добавления данных в секрет как есть стоит предварительно кодировать файл при помощи команды base64 и дописывать соотвествующее содержимое в yaml и применять заново.