## Практическое задание #5. Работа с Pulumi

Список задач практического задания:

* 5.1 [Создание статического ключа для доступа к Object Storage](#h5-1)
* 5.2 [Подготовка окружения для Pulumi](#h5-2)
* 5.3 [Создание Bucket в Object Storage](#h5-3)
* 5.4 [AWS CLI. Работа с файлами в Bucket](#h5-4)
* 5.5 [Удаление Bucket в Object Storage](#h5-5)


### 5.1 Создание статического ключа для доступа к Object Storage <a id="h5-1"/></a>

Подготовить переменные окружения
```bash
cd ~/labs/lab-05-pulumi

SA_ID=$(yc iam service-account list --limit=1 --format=json | jq -r .[0].id)
yc iam access-key create --service-account-id=$SA_ID --format=json > sa-key.json

export SA_KEY=$(cat sa-key.json | jq -r .access_key.key_id)
export SA_SECRET=$(cat sa-key.json | jq -r .secret)
export BUCKET=pulumi-$(yc iam service-account list --limit=1 --format=json | jq -r .[0].name | awk '{split($0,d,"-"); print d[2]}')-bucket
```

### 5.2 Подготовка окружения для Pulumi <a id="h5-2"/></a>

Инициализировать Pulumi проект:
```bash
mkdir cloud-app
cd cloud-app
pulumi login --local
export PULUMI_CONFIG_PASSPHRASE="default"
pulumi new --generate-only --name="cloud-app" --description="My Cloud App" --stack="dev" python
```

Установить зависимости для Python:
```bash
python3 -m venv venv
source venv/bin/activate
python3 -m pip install --upgrade pip setuptools wheel pulumi 
pip3 install pulumi_yandex
pulumi stack init dev
```

Подготовить переменные окружения в venv:
```bash
meta_id=$(curl -s 169.254.169.254/latest/meta-data/instance-id)
export YC_FOLDER_ID=$(yc compute instance get --id=$meta_id --format json | jq -r .folder_id)
export YC_CLOUD_ID=$(yc resource-manager folder get --id=$YC_FOLDER_ID --format json | jq -r .cloud_id)
export YC_TOKEN=$(yc iam create-token)
export PULUMI_CONFIG_PASSPHRASE=default
```

### 5.3 Создание Bucket в Object Storage <a id="h5-3"/></a>

Посмотреть на Python код, который будет выполняться pulumi
```bash
cat ../yc-objects.py
```

Запустить pulumi и создадть объекты в Yandex Cloud
```bash
cp ../yc-objects.py __main__.py
pulumi up
```

Убедиться через облачную веб-консоль, что сеть `pulumi-net` в VPC и бакет `pulumi-NNN-bucket`в Object Storage создались.


### 5.4 AWS CLI. Работа с файлами в Bucket <a id="h5-4"/></a>

[Ссылка на документацию AWS CLI](https://cloud.yandex.ru/docs/storage/tools/aws-cli)

Настроить AWS CLI для работы с YC Object Storage
```bash
echo $SA_KEY
echo $SA_SECRET
aws configure
```
Ввести следующие значения при запросе:
* AWS Access Key ID [None]: `содержимое переменной SA_KEY`
* AWS Secret Access Key [None]: `содержимое переменной SA_SECRET`
* Default region name [None]: `ru-central1`
* Default output format [None]:

Создать alias, в котором указать AWS CLI адрес endpoint в YC Object Storage
```bash
alias ycs3='aws s3 --endpoint-url=https://storage.yandexcloud.net'
```

Получить список бакетов в Object Storage
```bash
ycs3 ls
```

Скопировать локальный файл в бакет
```bash
ycs3 cp __main__.py s3://$BUCKET/yc-objects.py
```

Получить список файлов в bucket
```bash
ycs3 ls s3://$BUCKET
```

Загрузить файл из bucket и проверить его содержимое
```bash
ycs3 cp s3://$BUCKET/yc-objects.py yc-objects.py
cat yc-objects.py
```

Удалить файл в bucket и убедиться в этом
```bash
ycs3 rm s3://$BUCKET/yc-objects.py
ycs3 ls s3://$BUCKET
```

### 5.5 Удаление Bucket в Object Storage <a id="h5-5"/></a>

Удалить созданные ранее объекты с помощью Pulumi и деактивировать venv
```bash
pulumi destroy
deactivate
```

`Поздравляем! Это было заключительное задание в практикуме!`

### [ << задание 4 ](../lab-04-crossplane/README.md)
### [ << оглавление ](../README.md)
