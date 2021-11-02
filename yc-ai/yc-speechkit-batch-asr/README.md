# Batch recognizer — распознавание большого количества файлов 

Сценарий для распознавания больших архивов аудио.
<P>Аудио файлы должны быть предварительно конвертированы в формат, [который поддерживается SpeetchKit](https://cloud.yandex.ru/docs/speechkit/stt/formats), иметь расширение *.wav<br/>
Подготовленные файлы должны быть загружены на Object Storage. Для больших архивов поддерживаются вложенные папки с wav файлами.</P>

### Инструкция по установке:
<ol>
<li>Создайте в интерфейсе облака “бакет” – хранилище файлов куда можно будет загрузить аудиофайлы. https://cloud.yandex.ru/docs/storage/operations/buckets/create </li>
<li>Создайте сервисный аккаунт https://cloud.yandex.ru/docs/iam/operations/sa/create  с правами “editor” в том-же каталоге где был создан “бакет” 
  https://cloud.yandex.ru/docs/iam/operations/sa/assign-role-for-sa</li>
<li>Сгенерируйте статические ключи доступа для созданного сервисного аккаунта https://cloud.yandex.ru/docs/iam/operations/sa/create-access-key<<Обязательно запишите access key и secret key>> эти ключи будут нужны для авторизации программы в сервисе хранилища</li>
<li>Установите на рабочую станцию https://cloud.yandex.com/docs/cli/quickstart#install консоль облака для упрощенного получения токена авторизации в сервисе распознавания аудио.</li>
<liАвторизуйте YC от имени вашей учетной записи https://cloud.yandex.ru/docs/cli/operations/authentication/user или https://cloud.yandex.ru/docs/cli/operations/authentication/federated-user или от сервисного аккаунта из пункта 2</li>
<li>Скачайте актуальную версию   https://dotnet.microsoft.com/download</li>
  <li>Скомпилируйте приложение или скачайте и распакуйте <a href='https://github.com/yandex-cloud/yc-architect-solution-library/releases/tag/SpeechKit'> архив с релизом </a> в удобную директорию</li>
</ol>

### Инструкция по работе:
<ol>
 <li>Получите iam токен запустив YC (yc iam create-token)</li>
 <li>Запишите этот токен в переменную или сохраните в удобнее место</li>
 <li>Подготовить параметры запуска утилиты в соотв с приером ниже</li>
 <li>Для работы на windows используйте скомпилированный файл SkBatchAsrClient.exe</li>
 <li>Для работы на unix-based системах используйте приложение dotnet (из п5):
dotnet SkBatchAsrClient.dll</li>
</ol>

### Команда запускается в двух режимах:
<ul>
<li>- создание заданий на распознавание (запускается первым):
  <p> *** --mode stt_create_tasks ***</p>
</li>
<li>Получение результатов заданий (запускается для получения результатов):
  <p> ***  --mode stt_task_results</li>***</p>
</ul>

#### Пример команды на запуск процесса создания задач на распознавание:
```bsh
dotnet SkBatchAsrClient.dll  --s3-accessKey "xxxxxxx" --s3-secretKey  "xxxxxxx" --bucket my_s3_bycket_with_wav --iam-token “xxxxxxxxx" --folder-id xxxxxx   --audio-encoding Linear16Pcm --sample-rate 48000 --model="general:rc" --lang="ru-RU" --mode stt_create_tasks
``` 
#### Пример команды за получение результатов:
```bsh
dotnet SkBatchAsrClient.dll  --s3-accessKey "xxxxxxx" --s3-secretKey  "xxxxxxx" --bucket my_s3_bycket_with_wav --iam-token “xxxxxxxxx" --folder-id xxxxxx   --audio-encoding Linear16Pcm --sample-rate 48000 --model="general:rc" --lang="ru-RU" --mode stt_task_result
``` 

