# Добавление сертификатов для приватных container-registry на ноды Managed k8s кластера.

## Условия для использования (requirements)

* Managed k8s кластер c одной или несколькими нод группами в Yandex Cloud
* Сервисный аккаунт для нод-групп mk8s-кластера с дополнительными правами:
`certificate-manager.certificates.downloader`, `lockbox.payloadViewer`, `compute.viewer`, `kms.keys.encrypterDecrypter`,`container-registry.images.puller`, `container-registry.images.pusher`
* Установленный инструмент [**yc**](https://cloud.yandex.ru/docs/cli/quickstart) и [**jq**](https://jqlang.github.io/jq/)
* Загруженный ssh-private ключ в Yandex Cloud Lockbox
* Загруженный сертификат и private-ключ в Yandex Certificate Manager
* Существющий private-registry
* Container Registry в Yandex Cloud

## Описание

1. Для начала потребуется создать KMS ключ. Как это сделать, подробнее можно посмотреть в [**документации**](https://cloud.yandex.ru/docs/kms/operations/key#create)

2. Далее потребуется загрузить сертификат и ключ в Yandex Certificate Manager, подробнее также можно посмотреть в [**документации**].

3. Далее, в сервис Yandex Lockbox потребуется передать ssh-private ключ для доступа к нодам в mk8s-кластере.
Создать ключ можно такой командой:
`yc lockbox secret create --name <name> --payload "[{'key':'ssh-priv','text_value':'$(cat <path_to_key> | base64 -w 0)'}]" --kms-key-id <kms_id_key>`
Обратите внимание, что в `<name>` указывается имя сохраняемого секрета ssh-private-key в сервисе lockbox, в `<path_to_key>` указывать путь до приватного ключа на локальном ПК, и в `<kms_id_key>` передается id ранее созданного KMS-ключа.
(Можно обойтись и без шифрования секрета в сервисе Lockbox, не создавая KMS ключ и не указывая его при создании секрета, также не потребуются права`kms.keys.encrypterDecrypter` для сервисного аккаунта. НО! Мы не рекомендуем так делать из соображений безопасности.)

4. Далее создаем container-registry. Подробнее об этом в нашей [**документации**].
Создаем образ и закидываем ее в созданный container-registry (в `<container-registry-id>` указываем id созданного реестра):
`docker build -t yc-image:1.0 .`
`docker tag yc-image:1.0 cr.yandex/<container-registry-id>/yc-image:1.0`
`docker push cr.yandex/<container-registry-id>/yc-image:1.0`

5. Далее создаем `job.yaml`для использования в кластере:
```
apiVersion: batch/v1
kind: Job
metadata:
  name: yc-image
spec:
  template:
    spec:
      containers:
      - name: yc-image
        image: cr.yandex/<container-registry-id>/yc-image:1.0
        imagePullPolicy: Always
        env:
        - name: CLUSTER_ID
          value: ""
        - name: LOCKBOX_ID
          value: ""
        - name: CERT_ID
          value: ""
        - name: USR
          value: ""
        - name: VM
          value: ""
        command: ["/bin/bash", "-c"]
        args:
        - >
          /worker.sh &&
          ansible-playbook -i /inventory.json playbook.yaml -u $USR
      restartPolicy: Never
```
(В `CLUSTER_ID` указываем id кластера k8s, в `LOCKBOX_ID` указываем ID секрета, куда сохранили ssh-private key, `CERT_ID` указываем ID сертификата, который загрузили в Yandex Certificate Manager, в `USR` указываем пользователя для подключения по SSH и не забываем указать id container-registry в `image`.)

и применяем:
`kubectl apply -f job.yaml`

После того, как Job будет в состоянии `Completed`, ее можно удалить.
`kubectl delete jobs yc-image`

## Дополнительно
на шаге 5, можно возспользоваться интерактивным скриптом `interactive.sh`, который все необходимые IDs, запустит и удалит Job, когда она будет выполнена.
