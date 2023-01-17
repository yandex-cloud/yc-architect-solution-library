# Создание инстанса, базы данных и пользователей Postgresql и выдача пользователю прав только на чтение 



### Зачем нужен 

В Managed Postgresql процессы создания пользователя БД и выдачи ему прав разделены между API Yandex Cloud и непосредственно СУБД. Созадние пользователя - API, выдача прав - СУБД. Данные пример демонстрирует как создать пользователя БД и выдать ему права с помощью единого инструмента - terraform.

### Требования

* Консольная утилита управления Yandex Cloud [yc](https://cloud.yandex.com/docs/cli/quickstart)
* Облако (cloud\_id) и папка (folder\_id)
* Консольный клиент postgresql (psql)

> ВНИМАНИЕ: инстанс СУБД создается с публичным адресом
> НЕ ДЛЯ ИСПОЛЬЗОВАНИЯ В ПРОДУКТИВЕ!

### Описание

В процессе работы создаются следующие объекты в инфраструктуре Облака

* vpc
* subnet 
* security group
* managed postgresql
* postgresql user `user_owner` (database owner)
* postgresql database `db1`
* Объекты базы данных (таблицы с тестовыми данными)
* postgresql user `user_ro` (read only user)
* Права (grant) `SELECT` на все объекты схемы `public` для пользователя `user_ro`


### Подготовка и выполнение

1. Активировать рабочее окружение
      

    ```
    export YC_TOKEN=$(yc iam create-token)
    export TF_VAR_cloud_id=$(yc config get cloud-id)
    export TF_VAR_folder_id=$(yc config get folder-id)
    ```
1. Сгенерировать 2 пароля

    ```
    export TF_VAR_user_owner_passwd=$(openssl rand -base64 12)
    export TF_VAR_user_ro_passwd=$(openssl rand -base64 12)  
    ```
1. Инициализировать Terraform
 
    ```
    terraform init
    ```
1. Создать конфигурацию

    ```
    terraform apply
    ```
1. Проверить созданные объекты и права 

    ```
    export PGHOST=<имя хоста БД>
    ```

    ```
    export PGPORT=6432
    export PGPASSWORD="$TF_VAR_user_ro_passwd"
    
    ```
    ```
    psql db1 user_ro
    ```
    
    ```
    SELECT * FROM "movies"; -- успех
    DELETE FROM "movies"; -- ошибка permission denied
    
    ```
1. Удалить созданные ресурсы

    ```
    terraform destroy
    ```


