# Cronjob для Kubernetes

Данный чарт создает следующие ресурсы Kubernetes:

1. Cronjob
2. Secret для хранения конфигурации

По умолчанию, используются следующие переменные для имен директорий внутри бакета:
```
config:
  prefixIn: "input"
  prefixLog: "log"
  prefixOut: "out"
```

## Установка

1) Необходимо [создать](https://cloud.yandex.ru/docs/iam/operations/sa/create) сервисную учетную запись
2) [Назначить](https://cloud.yandex.ru/docs/iam/operations/sa/assign-role-for-sa) для сервисной учетной записи роли: `ai.speechkit-stt.user`, `storage.editor`
3) Создать [статический ключ доступа](https://cloud.yandex.ru/docs/iam/operations/sa/create-access-key)
4) Создать [API-ключ доступа](https://cloud.yandex.ru/docs/iam/operations/api-key/create)
5) Создать [бакет](https://cloud.yandex.ru/docs/storage/operations/buckets/create) в Object Storage

Необходимо заполнить переменные в файле `values.yaml`:
```
config:
  bucket: "xxx"     # имя бакета в Object Storage
  s3Key: "xxx"      # s3 ключ
  s3Secret: "xxx"   # s3 секрет
  apiSecret: "xxx"  # секрет api-ключа
```

После этого, можно установить Helm чарт:
```
helm install asr-batch helm/.
```

## Использование

После создания модуля, необходимо загрузить поддерживаемые аудио-файлы в созданный бакет, в директорию `input`.
При необходимости, измените язык распознавания в файле `config.json`, а файл сохраните в папке `input`.

`config.json` имеет простой формат, содержит только один параметр в формате JSON:
    ```
    {
        'lang': 'ru-RU'
    }
    ```

Cronjob будет запущен по расписанию, после чего – получит результат и сохранит его в папку `out`.
Статус работы функции можно отслеживать в логах подов, созданных cronjob-ом, а также по созданию, "движению" и содержимому файлов заданий в папках `log` и `out`.

## Удаление

Перед удалением, не забудьте очистить созданный бакет (иначе процесс удаления прервется):
```
helm uninstall asr-batch
```

## Использование образа Docker

Можно собрать собственный образ на основе `Dockerfile` и запускать его локально.
Необходимо указать переменные окружения в `Dockerfile`:

```
S3_BUCKET: xxx        # имя бакета
S3_PREFIX: xxx        # префикс для входящих файлов, например, input
S3_PREFIX_LOG: xxx    # префикс для обрабатываемых файлов, например, log
S3_PREFIX_OUT: xxx    # префикс для обработанных файлов, например, out
S3_KEY: xxx           # ключ для S3
S3_SECRET: xxx        # секрет для S3 ключа
API_SECRET: xxx       # секрет для API-ключа
```