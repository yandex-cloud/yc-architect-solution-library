# Суммирование трудозатрат в родительской задаче
Cloud-функцию необходимо вызывать из задач по условию изменения поля трудозатрат.

Если у задачи есть родительская задача, то указанные трудозатраты (последние) будут добавлены к родительской задаче.

В переменных окружения Cloud-функции необходимо передать переменные ORG - ID организации и TOKEN - OAuth токен пользователя.

## Настройка
1. Необходимо создать cloud функцию на python (https://cloud.yandex.ru/docs/functions/operations/function/function-create) и в созданной функции файлы с кодом функции - index.py и requirements.txt, аналогичные файлам в репозитории или загрузить приложенный zip-архив (tracker-summarize-spent.zip) в интрерфейсе редактора кода функции.
2. В переменных окружения необходимо добавить две переменных (ORG и TOKEN) - https://cloud.yandex.ru/docs/functions/operations/function/environment-variables-add с ID организации в Yandex Tracker и Oauth-токеном для возможности работы с API Yandex Tracker.
3. Необходимо создать в Yandex Tracker триггер, с действием типа http запрос и указать в адресе адрес функции (https://cloud.yandex.ru/docs/tracker/user/set-action#create-http), адрес функции можно получить на странице "Обзор функции" ("Ссылка для вызова"). Функция должна быть публичной или при вызове из Yandex Tracker можно использовать аутентификацию (https://cloud.yandex.ru/docs/functions/operations/function/auth).
