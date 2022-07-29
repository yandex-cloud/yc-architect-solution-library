Данный скрипт производит экспорт выбранных таблиц из Google Big Query в Google Storage. После чего производит копирование экспортированных данных
в Object Storage Яндекс Облака.
Необходимые пререквизиты:
1. По одному бакету на стороне Google Storage и Yandex Object Storage
2. Сервисный аккаунт на стороне Google Cloud, с доступами к проекту BigQuery (editor на проекте BQ) и бакету GS (uploader)
3. Сервисный аккаунт на стороне Yandex Cloud с доступом к бакету OBS (uploader)
4. Для сервисного акканута GCP подготовленный json файл с credentials
5. Для сервисного аккаунта YandexCloud - access key

Последовательность шагов:
1. Необходимо скачать утилиты CLI google-cloud-sdk: https://cloud.google.com/sdk/docs/install
2. Данный скрипт использует только утилиту gsutil, но для ее работы необходимо провести аутентификацию в gcloud CLI: https://cloud.google.com/sdk/docs/authorizing#authorizing_with_a_service_account
3. Необходимо установить Google BigQuery Python SDK: https://github.com/googleapis/python-bigquery
4. Для работы пакета bigquery необходимо передать путь к json-файлу в переменной окружения GOOGLE_APPLICATION_CREDENTIALS
5. Для работы утилиты gsutil необходимо заполнить своими параметрами файл .boto и передать путь к нему в переменной окружения BOTO_CONFIG
6. Обязательные аргументы для запуска скрипта: --bq_project, --gs_bucket, --bq_location=US, --yc_bucket
7. Не обязательный аргумент --gsutil_path указывается в случае, если gsutil не прописан в переменной PATH