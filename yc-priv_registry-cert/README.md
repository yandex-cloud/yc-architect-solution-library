# Добавление сертификатов для приватных container-registry на ноды Managed k8s кластера.

## Условия для использования (requirements)

* Managed k8s кластер c одной или несколькими нод группами в Yandex Cloud
* Сервисный аккаунт для нод-групп mk8s-кластера с дополнительными правами:
`certificate-manager.certificates.downloader`, `lockbox.payloadViewer`, `compute.viewer`, `kms.keys.decrypter`,`container-registry.images.puller`
(Многие из этих ролей могу уже быть включены или вложены в [**роли**](https://cloud.yandex.ru/docs/managed-kubernetes/security/#k8s-tunnel-clusters-agent) : `k8s.clusters.agent` или `k8s.tunnelClusters.agent`)
* Установленный инструмент [**yc**](https://cloud.yandex.ru/docs/cli/quickstart) и [**jq**](https://jqlang.github.io/jq/)
* Загруженный ssh-private ключ в Yandex Cloud Lockbox
* Загруженный сертификат и private-ключ в Yandex Certificate Manager
* Существющий private-registry
* Container Registry в Yandex Cloud
* Среда запуска контейнеров - `containerd`
* Дополнительная пара ssh-ключей для работы ansible (!ВАЖНО! Саму ssh-пару ключей следует создавать **без пароля**.)

## Описание

1. Для начала потребуется создать KMS ключ. Как это сделать, подробнее можно посмотреть в [**документации**](https://cloud.yandex.ru/docs/kms/operations/key#create)

2. Далее потребуется загрузить сертификат и ключ в Yandex Certificate Manager, подробнее также можно посмотреть в [**документации**](https://cloud.yandex.ru/docs/certificate-manager/operations/import/cert-create).

3. Далее, потребуется добавить дополнительный публичный ssh-ключ для доступа к нодам в группе(ах). Как это сделать, указывается в нашей документации [**документации**](https://cloud.yandex.ru/docs/managed-kubernetes/operations/node-connect-ssh#node-add-metadata)

4. Далее, в сервис Yandex Lockbox потребуется передать ssh-private ключ для доступа к нодам в mk8s-кластере.
Создать ключ в сервисе Yandex Lockbox можно такой командой:
`yc lockbox secret create --name <name> --payload "[{'key':'ssh-priv','text_value':'$(cat <path_to_key> | base64 -w 0)'}]" --kms-key-id <kms_id_key>`
Обратите внимание, что в `<name>` указывается имя сохраняемого секрета ssh-private-key в сервисе lockbox, в `<path_to_key>` указывается путь до приватного ключа на локальном ПК, и в `<kms_id_key>` передается id ранее созданного KMS-ключа.
(Можно обойтись и без шифрования секрета в сервисе Lockbox, не создавая KMS ключ и не указывая его при создании секрета, также не потребуются права`kms.keys.encrypterDecrypter` для сервисного аккаунта. НО! Мы не рекомендуем так делать из соображений безопасности.)

5. Далее создаем container-registry. Подробнее об этом в нашей [**документации**](https://cloud.yandex.ru/docs/container-registry/operations/registry/registry-create).
Создаем образ и закидываем ее в созданный container-registry (в `<container-registry-id>` указываем id созданного реестра):
```
docker build -t yc-image:1.0 .
docker tag yc-image:1.0 cr.yandex/<container-registry-id>/yc-image:1.0
docker push cr.yandex/<container-registry-id>/yc-image:1.0
```
6. В кластере создаем ConfigMap из playbook.yaml
```
kubectl create cm playbook --from-file playbook.yaml
```
7. ### Если группа(ы) узлов с фиксированным количеством нод: 
Создаем в кластере Job из манифеста job.yaml (предварительно добавив необходимую информацию):
```
kubectl apply -f job.yaml
```
  ### Если группа(ы) узлов с автомасштабированием:
Создаем в кластере CronJob.yaml из манифеста cronjob.yaml (предварительно добавив необходимую информацию):
```
kubectl apply -f cronjob.yaml
```
**Подробнее о переменных в манифестах**
(В `CLUSTER_ID` указываем id кластера k8s, в `LOCKBOX_ID` указываем ID секрета, в котором сохранили ssh-private key, `CERT_ID` указываем ID сертификата, который загрузили в Yandex Certificate Manager, в `USR` указываем пользователя для подключения по SSH, в `VM` указываем или все хосты - `all` или id(s) группы нод из кластера k8s (для передачи нескольких групп, ids следует разделять двоеточием(`:`), например, `cat2uia01tt04n106nde:cat8ppivgfg2nur22cik`)  и не забываем указать id container-registry в `image`.)

