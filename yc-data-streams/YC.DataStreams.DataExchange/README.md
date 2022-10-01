# Обмен данными через Yandex Data Streams

В этом решение показан простой способ взаимодействия между приложениями через Yandex Data Streams:
* __Producer__ отправляет данные в поток DataStream.
* __Consumer__ читает данные из потока DataStream.
* __Shared__ общая библиотека классов.

## Установка пакетов

AWSSDK.Kinesis пакет SDK for .NET для Amazon Kinesis совместимый с Yandex Data Streams.

```
Install-Package AWSSDK.Kinesis
```

Пакеты для загрузки конфигурации.
```
Install-Package Microsoft.Extensions.Configuration
Install-Package Microsoft.Extensions.Configuration.Json
```

## Настройки

1) [Выполните создание потока](https://cloud.yandex.ru/docs/data-streams/operations/manage-streams).
2) [Создайте сервисный аккаунт](https://cloud.yandex.ru/docs/data-streams/quickstart/).
3) Отредактировать файл _appsettings.json_.
* YC_Key_ID — статический ключ доступа. Замените _***_ на ключ, полученный на втором шаге.
* YC_Key_secret — секрет статического ключа доступа. Замените _***_ на секрет, полученный на втором шаге.
* адрес сервиса _serviceURL_: _https://yds.serverless.yandexcloud.net_.
* регион сервиса _region_: _ru-central1_.
* Идентификатор _folder_, в котором находится поток, например: b1g82kppqsd2m076av7h.
* Идентификатор _database_ Yandex Managed Service for YDB с потоком, например: etnp67d2bn66i70i0qav.
* Имя потока данных _streamName_, например _yads_.

```json
{
  "YandexCloudDataStreamConfiguration": {
    "YC_Key_ID": "***",
    "YC_Key_secret": "***",
    "serviceURL": "https://yds.serverless.yandexcloud.net",
    "region": "ru-central1",
    "folder": "b1g82kppqsd2m076av7h",
    "database": "etnp67d2bn66i70i0qav",
    "streamName": "yads"
  }
}
```

