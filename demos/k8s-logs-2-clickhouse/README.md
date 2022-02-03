# Log data shipping from Managed Kubernetes to Yandex Objct Storage (S3) и ClickHouse
## Создайте поток данных Yandex Data Streams
Выполнить [инструкцию по установке](https://cloud.yandex.ru/docs/data-streams/quickstart/create-stream)
Сохраните имя потока (--stream-name) для использования в значении переменной  ydsStream файла values.yaml

## Создайте AWS-совместимые статические ключи доступа
Выполнить [инструкцию посозданию ключей] (https://cloud.yandex.ru/docs/iam/concepts/authorization/access-key)
Сохраните значения для использования в значении переменных keyId и accessKey файла values.yaml

## Замените в файле values.yaml значения: 
  ```
  ydsStream: xxxx.xx 
  ycApiKey:
      keyId: "xxxxx"
      accessKey: "yyyyy"
  ```
[см. полный список сценариев здесь... ](https://github.com/yandex-cloud/yc-architect-solution-library/tree/main/demos)

* Разверните fluentbit, подключенный к Yandex DataS Streams через Kenezis Stream API, выполнив Helm chart из этого репозитория 
  ```
  helm install yds-fluentbit ./k8s-logs-ydt-ch
  ```
Убедитесь что pod с  fluentbit запустился и успешно передает данные в YDS
