# Batch recognizer — распознавание большого количества файлов 

Сценарий для распознавания больших архивов аудио.
<P>Аудио файлы должны быть предварительно конвертированы в формат, который поддерживается SpeetchKit (LPCM или Ogg) и загружены на Object Storage.</P>

### Инструкция по установке:
<ol>
<li>Создайте в интерфейсе облака “бакет” – хранилище файлов куда можно будет загрузить данные. https://cloud.yandex.ru/docs/storage/operations/buckets/create </li>
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
 <li>Для работы на windows используйте скомпилированный файл SkBatchAsrClient.exe</li>
 <li>Для работы на unix-based системах используйте приложение dotnet (из п5):
dotnet SkBatchAsrClient.dll</li>
</ol>
