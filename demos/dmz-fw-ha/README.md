# Реализация защищенной высокодоступной сетевой инфраструктуры с выделением DMZ на основе Next-Generation Firewall

## Содержание
- [Описание решения](#описание-решения)
- [Терминология](#терминология)
- [Архитектура решения и основные компоненты](#архитектура-решения-и-основные-компоненты)
- [Разворачиваемые сегменты и ресурсы](#разворачиваемые-сегменты-и-ресурсы)
- [Подготовка к развертыванию](#подготовка-к-развертыванию)
- [Развертывание Terraform сценария](#развертывание-terraform-сценария)
- [Действия после развертывания сценария](#действия-после-развертывания-сценария)
- [Подключение к сегменту управления](#подключение-к-сегменту-управления)
- [Настройка NGFW](#настройка-ngfw)
- [Проверка работоспособности](#проверка-работоспособности)
- [Проверка отказоустойчивости](#проверка-отказоустойчивости)
- [Требования к развертыванию в продуктивной среде](#требования-к-развертыванию-в-продуктивной-среде)
- [Удаление созданных ресурсов](#удаление-созданных-ресурсов)


## Описание решения

Сценарий разворачивает в Yandex Cloud облачную инфраструктуру для решения задач:
- защиты и сегментации инфраструктуры на зоны безопасности
- публикации приложений в интернет из зоны [DMZ](https://ru.wikipedia.org/wiki/DMZ_(компьютерные_сети))
- обеспечения высокой доступности развернутых приложений

Каждый сегмент сети (далее сегмент) содержит ресурсы одного назначения, обособленные от других ресурсов. Например, DMZ сегмент предназначен для размещения общедоступных приложений (обычно Frontend веб-сервера), а сегмент Application содержит Backend приложения. В облаке каждому сегменту соответствует свой каталог и своя облачная сеть VPC. Связь между сегментами происходит через виртуальные машины Next-Generation Firewall (NGFW), обеспечивающие комплексную защиту сегментов и контроль трафика между сегментами. 

Высокая доступность архитектуры достигается за счет:
- использования двух NGFW
- размещения ресурсов в двух зонах доступности
- сервиса [Application Load Balancer](#application-load-balancer) для отказоустойчивости и балансировки опубликованных приложений в DMZ
- [Облачных функций](#terraform-модуль-route-switcher) для переключения исходящего из сегмента трафика при отказе NGFW


## Архитектура решения и основные компоненты

<img src="./images/hld.png" alt="Архитектура решения" width="700"/>

Описание элементов схемы:

| Название элемента | Описание | Комментарии |
| ----------- | ----------- | ----------- | 
| VPC: public | Сегмент сети public | Для организации публичного доступа из интернет | 
| VPC: mgmt | Сегмент сети mgmt | Для управления облачной инфраструктурой и размещения служебных ресурсов | 
| VPC: dmz | Сегмент сети DMZ | Для размещения Frontend приложений, доступных из интернет | 
| VPC: app | Сегмент сети app | Для размещения Backend приложений | 
| VPC: database | Сегмент сети database | Для размещения баз данных |
| FW-A | Виртуальная машина Check Point NGFW | Для защиты инфраструктуры и сегментации сети на зоны безопасности. Активен для входящего трафика и исходящего трафика. |
| FW-B | Виртуальная машина Check Point NGFW | Для защиты инфраструктуры и сегментации сети на зоны безопасности. Активен для входящего трафика и в резерве для исходящего трафика. |
| ALB | Балансировщик нагрузки на FW-A и FW-B | Для балансировки и отказоустойчивости опубликованных в DMZ приложений |
| route-checker функция | Облачная функция | Для проверки состояния NGFW и принятия решения о переключении исходящего трафика в сегменте | 
| route-switcher функция | Облачная функция | Для переключения таблицы маршрутизации в сегменте | 
| Jump ВМ | Виртуальная машина c настроенным [WireGuard VPN](https://www.wireguard.com/) | Для защищенного VPN подключения к сегменту управления |
| Сервер управления FW | Виртуальная машина c ПО Check Point Security Management | Для централизованного управления решением Check Point NGFW |
| NLB | Сетевой балансировщик на группу веб-серверов | Для балансировки трафика на веб-серверы тестового приложения в DMZ сегменте |
| Приложение | ВМ с веб-сервером Nginx | Пример тестового приложения, развернутого в DMZ сегменте |

</details>

Ключевыми элементами решения являются: 
- [Next-Generation Firewall](#next-generation-firewall)
- [Application Load Balancer](#application-load-balancer)
- [Terraform модуль route-switcher](#terraform-модуль-route-switcher)
- [Группы безопасности](#группы-безопасности)

FW-A и FW-B работают в режиме Active/Active для входящего в DMZ трафика и в режиме Active/Standby для исходящего трафика из сегментов.

<img src="./images/traffic_flows.png" alt="Прохождение трафика через NGFW для входящего и исходящего направлений" width="700"/>

В случае отказа FW-A сетевая связанность с интернетом и между сегментами будет выполняться через FW-B

<img src="./images/traffic_flows_failure.png" alt="Прохождение трафика через FW-B при отказе основного FW-B для входящего и исходящего направлений" width="700"/>


### Next-Generation Firewall

NGFW используется для защиты и сегментации облачной сети с выделением DMZ зоны для размещения публичных приложений.
В [Yandex Cloud Marketplace](https://cloud.yandex.ru/marketplace?categories=security) доступно несколько вариантов NGFW.

В данном сценарии развернуто решение [Check Point CloudGuard IaaS](https://cloud.yandex.ru/marketplace/products/checkpoint/cloudguard-iaas-firewall-tp-payg-m):
- Межсетевой экран, NAT, предотвращение вторжений, антивирус и защита от ботов
- Гранулярный контроль трафик на уровне приложений, логирование сессий
- Централизованное управление с помощью решения Check Point Security Management
- Решение Check Point в данном примере настроено с базовыми политиками доступа (Access Control) и NAT

Решение Check Point CloudGuard IaaS доступно в Yandex Cloud Marketplace в вариантах Pay as you go и BYOL. В этом примере используется BYOL вариант с Trial периодом 15 дней:
- 2 ВМ NGFW [Check Point CloudGuard IaaS - Firewall & Threat Prevention BYOL](https://cloud.yandex.ru/marketplace/products/checkpoint/cloudguard-iaas-firewall-tp-byol-m)
- ВМ сервера управления [Check Point CloudGuard IaaS - Security Management BYOL](https://cloud.yandex.ru/marketplace/products/checkpoint/cloudguard-iaas-security-management-byol-m)

Для использования в продуктивной среде рекомендуется рассматривать варианты:
- NGFW [Check Point CloudGuard IaaS - Firewall & Threat Prevention PAYG](https://cloud.yandex.ru/marketplace/products/checkpoint/cloudguard-iaas-firewall-tp-payg-m)
- Для сервера управления Check Point CloudGuard IaaS - Security Management необходимо приобрести отдельную лицензию либо использовать свою on-prem инсталляцию сервера управления

Ссылки на вебинары по использованию решений Check Point в Yandex Cloud
- [Check Point в Yandex Cloud Marketplace](https://youtu.be/qvR9G_oDfnE)
- [Обзор и установка CloudGuard IaaS Gateway в Yandex Cloud](https://youtu.be/LtQltM71cUw)
- [Установка CloudGuard IaaS Security Management и Standalone в Yandex Cloud](https://youtu.be/MraLOJRDWts)

### Application Load Balancer (ALB)

<img src="./images/alb.png" alt="Application Load Balancer в связке с FW" width="400"/>

Для балансировки трафика приложений и отказоустойчивости в работе приложений, опубликованных в DMZ, используется [ALB](https://cloud.yandex.ru/docs/application-load-balancer/concepts/), который балансирует запросы пользователей на public интерфейсы FW-A и FW-B. Таким образом обеспечивается работа FW-A и FW-B в режиме Active/Active для входящего трафика в DMZ.
В примере используется группа бэкендов Stream (TCP) с [привязкой пользовательской сессии](https://cloud.yandex.ru/docs/application-load-balancer/concepts/backend-group#session-affinity) к эндпойнту (FW) на основе IP адреса пользователя.
По умолчанию балансировщик ALB равномерно распределяет трафик между FW-A и FW-B. Можно настроить [локализацию трафика](https://cloud.yandex.ru/docs/application-load-balancer/concepts/backend-group#locality), чтобы ALB отправлял запросы к FW той зоны доступности, в которой балансировщик принял запрос. Если в этой зоне доступности нет работающего FW, балансировщик отправит запрос в другую зону.


> **Важная информация**
>  
> На FW-A и FW-B необходимо настроить Source NAT на IP адрес FW в сегменте dmz для обеспечения прохождения ответа от приложения через тот же FW, через который поступил запрос от пользователя. Смотрите раздел [Настройка NGFW](#настройка-ngfw) пункт 11.

Application Load Balancer предоставляет расширенные возможности, среди которых:
- Поддержка протоколов: HTTP/S, HTTP/S WebSocket, TCP/TLS, HTTP/S gRPC 
- Гибкое распределение трафика между бэкендами приложений
- Обработка TLS-трафика: установка соединения и терминация TLS-сессий с помощью сертификатов из Yandex Сertificate Manager
- Возможность привязки пользовательской сессии и выбор режимов балансировки
- Создание и модификация ответов на запросы
- Анализ логов


### Terraform модуль route-switcher

В облачной сети Yandex Cloud не поддерживается работа протоколов VRRP/HSRP между FW. 

Для обеспечения отказоустойчивости исходящего трафика из сегмента модуль route-switcher выполняет следующие действия:
- Переключение таблиц маршрутизации для подсетей при отказе FW-A на FW-B
- Возврат таблиц маршрутизации через FW-A после его восстановления

В данном сценарии подсети используют таблицу маршрутизации через FW-A для исходящего из сегмента трафика.

Среднее время реакции на сбой составляет 1 мин (обусловлено алгоритмом работы функции route-checker).

<img src="./images/module_route-switcher.png" alt="Terraform модуль route-switcher" width="600"/>

Модуль route-switcher создает две облачные функции для каждого сегмента (в соответствующем каталоге), в котором необходимо обеспечить отказоустойчивость для исходящего трафика:
- Облачная функция route-checker для проверки состояния FW-A и FW-B и принятия решения о переключении таблицы маршрутизации в сегменте
- Облачная функция route-switcher для переключения таблицы маршрутизации в сегменте

Модуль route-switcher создает также общие ресурсы в каталоге mgmt, необходимые для работы функций route-checker и route-switcher:
- NLB: мониторинг доступности FW-A и FW-B
- Бакет в Object Storage: хранение файлов конфигураций для каждого сегмента
    - состояние FW-A и FW-B (рабочее/нерабочее) 
    - список подсетей 
    - активная таблица маршрутизации
- Очереди сообщений для каждого сегмента: для асинхронного выполнения функций и масштабирования

Модуль route-switcher в этом примере является измененной версией [исходного модуля](https://github.com/yandex-cloud/yc-architect-solution-library/tree/main/yc-route-switcher/examples/ubuntu-firewall).
Изменена функция route-checker в связи с необходимостью работы пары FW в режиме Active/Standby для исходящего трафика из сегмента.


#### Алгоритм работы функции route-checker

<details>
<summary>Посмотреть подробности</summary>

Route-checker вызывается по триггеру раз в минуту, проверяет, в каком состоянии находится FW-A, и принимает решение о переключении таблицы маршрутизации для подсетей в сегменте. Если возникает необходимость в переключении таблицы маршрутизации, то функция отправляет сообщение в очередь сообщений для сегмента.

![Алгоритм работы функции route-checker](./images/route-checker.png)

</details>


#### Алгоритм работы функции route-switcher

<details>
<summary>Посмотреть подробности</summary>

Route-switcher вызывается при поступлении в очередь сообщения от функции route-checker и меняет для подсети таблицу маршрутизации.

![Алгоритм работы функции route-switcher](./images/route-switcher.png)

</details>


### Группы безопасности

Группы безопасности используются для контроля трафика между ресурсами внутри сегмента.

В данном сценарии группы безопасности разрешают входящий трафик по портам TCP 443, 22 и ICMP пакеты от источников внутри группы, а также разрешают любой исходящий трафик. Группы безопасности в сегментах mgmt, dmz, public также имеют дополнительные разрешения, например, для работы балансировщиков, NGFW и других развернутых ресурсов.

## Разворачиваемые сегменты и ресурсы

Решение создает в облаке ресурсы для 8 сегментов 

<details>
<summary>Посмотреть подробности</summary>

| Сегмент | Описание | Ресурсы | Каталоги и сети | Группы безопасности | Функции route-switcher и route-checker | 
| ----------- | ----------- | ----------- | ----------- | ----------- |----------- |
| public | публичный доступ из интернет | ALB | + | + | |
| mgmt | управление облачной инфраструктурой | 2 x Check Point NGFW, сервер управления Check Point, Jump ВМ с WireGuard для подключения из интернет, NLB для проверки доступности NGFW, бакет для хранения файлов конфигураций сегмента, очереди сообщений | + | + | + |
| dmz | для размещения Frontend приложений, доступных из интернет | NLB для балансировки по веб-серверам, группа виртуальных машин с 2-мя веб-серверами Nginx для примера | + | + | + |
| app | для размещения Backend приложений | | + | + | + |
| database | для размещения баз данных | | + | + | + |
| vpc6 | на будущее | | + | + | |
| vpc7 | на будущее | | + | + | |
| vpc8 | на будущее | | + | + | |

</details>


## Подготовка к развертыванию

1. Перед выполнением развертывания нужно [зарегистрироваться в Yandex Cloud и создать платежный аккаунт](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart#before-you-begin)

2. [Установите Terraform](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart#install-terraform)

3. [Установите и настройте Yandex Cloud CLI](https://cloud.yandex.ru/docs/cli/quickstart)

4. [Установите Git](https://github.com/git-guides/install-git)

5. Проверьте наличие учетной записи в облаке с правами admin на облако

6. Проверьте квоты в облаке, чтобы была возможность развернуть ресурсы в сценарии:

    <details>
    <summary>Посмотреть справочную информацию по количеству ресурсов, создаваемых в сценарии</summary>

    | Ресурс | Количество |
    | ----------- | ----------- |
    | Каталоги | 8 |
    | Группы виртуальных машин | 1 |
    | Виртуальные машины | 6 |
    | vCPU виртуальных машин | 18 |
    | RAM виртуальных машин | 30 ГБ |
    | Диски | 6 |
    | Объем SSD дисков | 360 ГБ |
    | Объем HDD дисков | 30 ГБ |
    | Облачные сети | 8 |
    | Подсети | 16 |
    | Таблицы маршрутизации | 8 |
    | Группы безопасности | 11 |
    | Статические публичные IP-адреса | 2 |
    | Публичные IP-адреса | 2 |
    | Статические маршруты | 34 |
    | Бакеты | 1 |
    | Cloud функции | 8 |
    | Триггеры для cloud функций | 8 |
    | Общий объём RAM всех запущенных функций | 1.024 ГБ |
    | Балансировщики NLB | 2 |
    | Целевые группы для NLB | 2 |
    | Балансировщики ALB | 1 |
    | Группы бэкендов для ALB | 1 |
    | Целевые группы для ALB | 1 |

    </details>


## Развертывание Terraform сценария

1. Склонируйте репозиторий `yandex-cloud/yc-architect-solution-library` из GitHub и перейдите в папку сценария `dmz-fw-ha`:
    ```bash
    git clone https://github.com/yandex-cloud/yc-architect-solution-library.git
    cd yc-architect-solution-library/demos/dmz-fw-ha
    ```

2. Настройте окружение для развертывания ([подробности](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart#get-credentials)):
    ```bash
    export YC_TOKEN=$(yc iam create-token)
    ```

3. Заполните файл `terraform.tfvars` вашими значениями переменных. Файл содержит примеры значений, но вы можете заменить их своими данными (идентификатор облака, название vpc, подсети, порт приложения в DMZ, параметры для подключения к Jump ВМ). Обязательно укажите идентификатор вашего облака `cloud_id`. Рекомендуется указать все 8 сегментов с расчетом на будущее их использование, т.к. ВМ с образом NGFW в облаке не поддерживает добавление новых сетевых интерфейсов после её создания. 

    <details>
    <summary>Посмотреть переменные в terraform.tfvars</summary>

    | Название | Описание | Пример значения |
    | ----------- | ----------- | ----------- |
    | cloud_id | Идентификатор вашего облака в Yandex Cloud | b1g8dn6s3v2eiid9dbci |
    | public_app_port | TCP порт для опубликованного в DMZ приложения, на котором балансировщик ALB будет принимать входящий трафик от пользователей | "80" |
    | internal_app_port | Внутренний TCP порт опубликованного в DMZ приложения, на который балансировщик ALB будет направлять трафик. Может отличаться от public_app_port или совпадать с ним. | "8080" |
    | trusted_ip_for_access_jump-vm | Список публичных IP адресов/подсетей, с которых разрешено подключение к Jump ВМ. Используется во входящем правиле группы безопасности для Jump ВМ.  | ["A.A.A.A/32", "B.B.B.0/24"] |
    | wg_port | UDP порт для входящих соединений в настройках WireGuard на Jump ВМ | "51820" |
    | wg_client_dns | Список адресов DNS серверов в облачной сети управления, которые будет использовать рабочая станция администратора после поднятия туннеля WireGuard к Jump ВМ | "192.168.1.2, 192.168.2.2" |
    | jump_vm_admin_username | Имя пользователя для подключения к Jump ВМ | "admin" |
    | **Сегмент 1** |
    | vpc_name_1 | Название VPC и каталога для 1-го сегмента | "demo-dmz" |
    | subnet-a_vpc_1 | Подсеть в зоне A для 1-го сегмента | "10.160.1.0/24" | 
    | subnet-b_vpc_1 | Подсеть в зоне B для 1-го сегмента | "10.160.2.0/24" | 
    | **Сегмент 2** |||
    | vpc_name_2 | Название VPC и каталога для 2-го сегмента | "demo-app" |
    | subnet-a_vpc_2 | Подсеть в зоне A для 2-го сегмента | "10.161.1.0/24" | 
    | subnet-b_vpc_2 | Подсеть в зоне B для 2-го сегмента | "10.161.2.0/24" | 
    | **Сегмент 3** |||
    | vpc_name_3 | Название VPC и каталога для 3-го сегмента | "demo-public" |
    | subnet-a_vpc_3 | Подсеть в зоне A для 3-го сегмента | "172.16.1.0/24" | 
    | subnet-b_vpc_3 | Подсеть в зоне B для 3-го сегмента | "172.16.2.0/24" | 
    | **Сегмент 4** |||
    | vpc_name_4 | Название VPC и каталога для 4-го сегмента | "demo-mgmt" |
    | subnet-a_vpc_4 | Подсеть в зоне A для 4-го сегмента | "192.168.1.0/24" | 
    | subnet-b_vpc_4 | Подсеть в зоне B для 4-го сегмента | "192.168.2.0/24" | 
    | **Сегмент 5** |||
    | vpc_name_5 | Название VPC и каталога для 5-го сегмента | "demo-database" |
    | subnet-a_vpc_5 | Подсеть в зоне A для 5-го сегмента | "10.162.1.0/24" | 
    | subnet-b_vpc_5 | Подсеть в зоне B для 5-го сегмента | "10.162.2.0/24" | 
    | **Сегмент 6** |||
    | vpc_name_6 | Название VPC и каталога для 6-го сегмента | "demo-vpc6" |
    | subnet-a_vpc_6 | Подсеть в зоне A для 6-го сегмента | "10.163.1.0/24" | 
    | subnet-b_vpc_6 | Подсеть в зоне B для 6-го сегмента | "10.163.2.0/24" | 
    | **Сегмент 7** |||
    | vpc_name_7 | Название VPC и каталога для 7-го сегмента | "demo-vpc7" |
    | subnet-a_vpc_7 | Подсеть в зоне A для 7-го сегмента | "10.164.1.0/24" | 
    | subnet-b_vpc_7 | Подсеть в зоне B для 7-го сегмента | "10.164.2.0/24" | 
    | **Сегмент 8** |||
    | vpc_name_8 | Название VPC и каталога для 8-го сегмента | "demo-vpc8" |
    | subnet-a_vpc_8 | Подсеть в зоне A для 8-го сегмента | "10.165.1.0/24" | 
    | subnet-b_vpc_8 | Подсеть в зоне B для 8-го сегмента | "10.165.2.0/24" |

    </details>

4. Выполните инициализацию Terraform:
    ```bash
    terraform init
    ```

5. Проверьте конфигурацию Terraform файлов:
    ```bash
    terraform validate
    ```

6. Проверьте список создаваемых облачных ресурсов:
    ```bash
    terraform plan
    ```

7. Создайте ресурсы. На развертывание всех ресурсов в облаке потребуется около 7 мин:
    ```bash
    terraform apply
    ```

8. После завершения процесса terraform apply в командной строке будет выведен список информации о развернутых ресурсах. В дальнейшем его можно будет посмотреть с помощью команды `terraform output`:

    <details>
    <summary>Посмотреть информацию о развернутых ресурсах</summary>

    | Название | Описание | Пример значения |
    | ----------- | ----------- | ----------- |
    | dmz-web-server-nlb_ip_address | IP адрес балансировщика трафика в сегменте dmz, за которым находится целевая группа с веб-серверами для тестирования публикации приложения из dmz. Используется для настройки Destination NAT в FW. | "10.160.1.100" |
    | fw-a_ip_address | IP адрес в сети управления для FW-A | "192.168.1.10" |
    | fw-alb_public_ip_address | Публичный IP адрес балансировщика ALB. Используется для обращения к опубликованному в DMZ приложению из интернет. | "C.C.C.C" |
    | fw-b_ip_address | IP адрес в сети управления для FW-B | "192.168.2.10" |
    | fw_gaia_portal_mgmt-server_password | Пароль по умолчанию для первоначального подключения по https к IP адресу сервера управления FW | "admin" |
    | fw_mgmt-server_ip_address | IP адрес в сети управления для сервера управления FW | "192.168.1.100" |
    | fw_sic-password | Однократный пароль (SIC) для добавления FW в сервер управления FW | Не показывается в общем выводе `terraform output`. Для отображения значения используйте `terraform output fw_sic-password` |
    | fw_smartconsole_mgmt-server_password | Пароль для подключения к серверу управления FW с помощью графического приложения Check Point SmartConsole | Не показывается в общем выводе `terraform output`. Для отображения значения используйте `terraform output fw_smartconsole_mgmt-server_password` |
    | jump-vm_path_for_WireGuard_client_config | Файл конфигурации для защищенного VPN подключения с помощью клиента WireGuard к Jump ВМ | "./jump-vm-wg.conf" |
    | jump-vm_public_ip_address_jump-vm | Публичный IP адрес Jump ВМ | "D.D.D.D" |
    | path_for_private_ssh_key | Файл с private ключом для подключения по протоколу SSH к ВМ (jump-vm, fw-a, fw-b, mgmt-server, веб-серверы в сегменте dmz) | "./pt_key.pem" |

    </details>

## Действия после развертывания сценария

После успешного развертывания сценария Terraform рекомендуется выполнить следующую последовательность действий:
1. Ознакомиться с [требованиями к развертыванию в продуктивной среде](#требования-к-развертыванию-в-продуктивной-среде)
2. [Подключиться к сегменту управления](#подключение-к-сегменту-управления) с помощью Jump ВМ для настройки решения Check Point NGFW и доступа по SSH к развернутым ресурсам в облаке
3. [Настроить NGFW](#настройка-ngfw) под задачи вашей инфраструктуры или согласно приведенным шагам в качестве примера 
4. Выполнить базовую [проверку работоспособности](#проверка-работоспособности) решения 
5. Выполнить базовую [проверку отказоустойчивости](#проверка-отказоустойчивости) решения 

> **Важная информация**
> 
> Без шагов настройки NGFW проверить работоспособность и отказоустойчивость решения не получится.


## Подключение к сегменту управления

После выполнения развертывания в mgmt сегменте сети управления появляется Jump ВМ на основе образа Ubuntu с настроенным [WireGuard VPN](https://www.wireguard.com/) для защищенного подключения. После установления VPN туннеля к Jump ВМ на рабочей станции администратора появятся маршруты через VPN туннель к подсетям сегментов mgmt, dmz, app, database.  
Вы также можете подключиться к Jump ВМ по SSH, используя SSH ключ и логин из вывода `terraform output`.

1. Установите на рабочую станцию администратора [приложение WireGuard](https://www.wireguard.com/install/) для вашей операционной системы.

2. В папке с Terraform сценарием после создания ресурсов появляется файл `jump-vm-wg.conf` с настройками клиента WireGuard для подключения к Jump ВМ. Добавьте новый туннель (Import tunnel(s) from file) в приложении WireGuard для Windows или Mac OS, используя файл `jump-vm-wg.conf`. Активируйте туннель нажатием на кнопку Activate.  

3. Проверьте в командной строке с помощью `ping 192.168.1.100` сетевую связность с сервером управления FW через VPN туннель WireGuard. 

## Настройка NGFW

Вы можете настроить развернутые FW-A и FW-B под ваши задачи в соответствие с корпоративной политикой безопасности. Для управления и настройки решения Check Point используется графическое приложение SmartConsole, доступное для операционной системы Windows. 

В качестве примера приводятся шаги настройки FW-A и FW-B с базовыми политиками доступа (Access Control) и NAT, необходимыми для проверки работоспособности и тестирования отказоустойчивости в сценарии, но не являющимися достаточными для развертывания инфраструктуры в продуктивной среде.

Шаги настройки NGFW в этом сценарии состоят из следующей последовательности действий, выполняемых в SmartConsole:
- Добавление FW-A и FW-B
- Настройка сетевых интерфейсов FW-A и FW-B
- Создание сетевых объектов 
- Настройка политик доступа (Access Control - Policy)
- Настройка политик NAT трансляций (Access Control - NAT)

1. Подключитесь к серверу управления FW по https://192.168.1.100. Учетная запись администратора: логин `admin`, пароль `admin`. Откроется Gaia Portal. После подключения замените пароль, выбрав `User Management > Change My Password`.

2. На главной странице Gaia Portal скачайте графическое приложение SmartConsole по ссылке в верху страницы: `Manage Software Blades using SmartConsole. Download Now!` Приложение SmartConsole требует операционной системы Windows. Установите SmartConsole на рабочую станцию администратора.

3. Зайдите в SmartConsole, укажите для подключения логин `admin`, IP адрес сервера управления `192.168.1.100` и пароль из вывода команды `terraform output fw_smartconsole_mgmt-server_password`.

4. Добавьте FW-A и FW-B в сервер управления (действие New Gateway), используя Wizard:
    - название FW: FW-a и FW-b
    - тип Gateway: CloudGuard IaaS 
    - Gateway IP: IP адрес FW в mgmt сегменте (`192.168.1.10` для FW-A и `192.168.2.10` для FW-B)
    - Initiated trusted communication now: One-time SIC пароль из вывода команды `terraform output fw_sic-password`

5. Настройте сетевые интерфейсы для каждого FW (`Network Management > Topology Settings`):
    - Переименуйте Network Groups, созданные по умолчанию на основе статических маршрутов в FW (например, переименуйте FW-a_eth0 в mgmt)
    - Укажите Security Zone
    - Проверьте, что Anti Spoofing включен (Prevent and Log)
    - Настройте для dmz сетей (Net_10.160.1.0 и Net_10.160.2.0) Automatic Hide NAT трансляции, чтобы выполнялся Source NAT на public интерфейс FW для трафика, инициируемого в dmz сегменте в интернет 

    <details>
    <summary>Настройка интерфейсов для FW-A</summary>

    | Interface | IPv4 address/mask | Leads To | Security Zone | Anti Spoofing |
    | ----------- | ----------- | ----------- | ----------- | ----------- |
    | eth0 | 192.168.1.10/24 | FW-a_eth0 -> mgmt (Internal) | InternalZone | Prevent and Log |
    | eth1 | 172.16.1.10/24 | Internet (External) | ExternalZone | Prevent and Log |
    | eth2 | 10.160.1.10/24 | FW-a_eth2 -> dmz, DMZ (Internal) | DMZZone | Prevent and Log |
    | eth3 | 10.161.1.10/24 | FW-a_eth3 -> app (Internal) | InternalZone | Prevent and Log |
    | eth4 | 10.162.1.10/24 | FW-a_eth4 -> database (Internal) | InternalZone | Prevent and Log |
    | eth5 | 10.163.1.10/24 | This Network (Internal) | InternalZone | Prevent and Log |
    | eth6 | 10.164.1.10/24 | This Network (Internal) | InternalZone | Prevent and Log |
    | eth7 | 10.165.1.10/24 | This Network (Internal) | InternalZone | Prevent and Log |

    <img src="./images/fw-a_topology_all_intf.png" alt="Интерфейсы FW-A" width="400"/>    

    <details>
    <summary>Настройка mgmt интерфейса FW-A</summary>

    ![FW-A_eth0](./images/fw-a_topology_eth0.png)

    </details>
    
    <details>
    <summary>Настройка public интерфейса FW-A</summary>

    ![FW-A_eth1](./images/fw-a_topology_eth1.png)

    </details>

    <details>
    <summary>Настройка dmz интерфейса FW-A</summary>

    ![FW-A_eth2](./images/fw-a_topology_eth2.png)

    </details>

    <details>
    <summary>Настройка NAT для dmz подсети зоны A</summary>

    ![NAT dmz-a](./images/fw-a_topology_eth2_nat_dmz-a.png)

    </details>

    <details>
    <summary>Настройка NAT для dmz подсети зоны B</summary>

    ![NAT dmz-b](./images/fw-a_topology_eth2_nat_dmz-b.png)

    </details>

    <details>
    <summary>Настройка app интерфейса FW-A</summary>

    ![FW-A_eth3](./images/fw-a_topology_eth3.png)

    </details>

    <details>
    <summary>Настройка database интерфейса FW-A</summary>

    ![FW-A_eth4](./images/fw-a_topology_eth4.png)

    </details>

    </details>

    <details>
    <summary>Настройка интерфейсов для FW-B</summary>

    | Interface | IPv4 address/mask | Leads To | Security Zone | Anti Spoofing |
    | ----------- | ----------- | ----------- | ----------- | ----------- |
    | eth0 | 192.168.2.10/24 | FW-b_eth0 -> mgmt (Internal) | InternalZone | Prevent and Log |
    | eth1 | 172.16.2.10/24 | Internet (External) | ExternalZone | Prevent and Log |
    | eth2 | 10.160.2.10/24 | FW-b_eth2 -> dmz, DMZ (Internal) | DMZZone | Prevent and Log |
    | eth3 | 10.161.2.10/24 | FW-b_eth3 -> app (Internal) | InternalZone | Prevent and Log |
    | eth4 | 10.162.2.10/24 | FW-b_eth4 -> database (Internal) | InternalZone | Prevent and Log |
    | eth5 | 10.163.2.10/24 | This Network (Internal) | InternalZone | Prevent and Log |
    | eth6 | 10.164.2.10/24 | This Network (Internal) | InternalZone | Prevent and Log |
    | eth7 | 10.165.2.10/24 | This Network (Internal) | InternalZone | Prevent and Log |

    <img src="./images/fw-b_topology_all_intf.png" alt="Интерфейсы FW-B" width="400"/>

    Настройка интерфейсов FW-B проводится аналогично FW-A (смотрите скриншоты интерфейсов для FW-A).

    </details>

6. Создайте Networks Objects:

    | Object name | Network address | Net mask |
    | ----------- | ----------- | ----------- |
    | public - a | 172.16.1.0 | 255.255.255.0 |
    | public - b | 172.16.2.0 | 255.255.255.0 |

    <details>
    <summary>Скриншот Networks Objects, Hosts, Groups</summary>

    ![Networks Objects](./images/network_objects.png)

    </details>

7. Создайте Network Group:

    | Name | Network objects |
    | ----------- | ----------- |
    | public | public - a, public - b |

    <details>
    <summary>Скриншот Network Group</summary>

    <img src="./images/network_group.png" alt="Network Group" width="500"/>

    </details>

8. Создайте Hosts:

    | Object name | IPv4 address |
    | ----------- | ----------- |
    | dmz-web-server | 10.160.1.100 |
    | FW-a-dmz-IP | 10.160.1.10 |
    | FW-a-public-IP | 172.16.1.10 |
    | FW-b-dmz-IP | 10.160.2.10 |
    | FW-b-public-IP | 172.16.2.10 |

    <details>
    <summary>Скриншот Networks Objects, Hosts, Groups</summary>

    ![Hosts](./images/network_objects.png)

    </details>

9. Создайте TCP Service для развернутого приложения в dmz сегменте: 

    | Name | Port |
    | ----------- | ----------- |
    | TCP_8080 | 8080 |

    <details>
    <summary>Скриншот TCP Service</summary>

    <img src="./images/tcp_8080_service.png" alt="TCP Service" width="400"/>

    </details>

10. Добавьте правила в Access Control - Policy. Ниже приведен пример базовых правил для проверки работы политик FW, прохождения NLB healtcheck, публикации тестового приложения из dmz сегмента и тестирования отказоустойчивости.

    | No | Name | Source | Destination | VPN | Services & Applications | Action | Track | Install On |
    | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- |
    | 1 | Web-server port forwarding on FW-a | public | FW-a-public-IP | Any | TCP_8080 | Accept | Log | FW-a |
    | 2 | Web-server port forwarding on FW-b | public | FW-b-public-IP | Any | TCP_8080 | Accept | Log | FW-b |
    | 3 | FW management & NLB healthcheck | mgmt | FW-a, FW-b, mgmt-server | Any | https, ssh | Accept | Log | Policy Targets (All gateways)  |
    | 4 | Stealth | Any | FW-a, FW-b, mgmt-server | Any | Any | Drop | Log | Policy Targets (All gateways) |
    | 5 | mgmt to DMZ | mgmt | dmz | Any | Any | Accept | Log | Policy Targets (All gateways) |
    | 6 | mgmt to app | mgmt | app | Any | Any | Accept | Log | Policy Targets (All gateways) |
    | 7 | mgmt to database | mgmt | database | Any | Any | Accept | Log | Policy Targets (All gateways) |
    | 8 | ping from dmz to internet | dmz | ExternalZone | Any | icmp-reguests (Group) | Accept | Log | Policy Targets (All gateways) |
    | 9 | Cleanup rule | Any | Any | Any | Any | Drop | Log | Policy Targets (All gateways) |

    <details>
    <summary>Описание правил политики доступа Access Control - Policy</summary>

    | Номер | Имя | Описание |
    | ----------- | ----------- | ----------- |
    | 1 | Web-server port forwarding on FW-a | Разрешение доступа из public сегмента к опубликованному в dmz сегменте приложению по порту TCP 8080 для FW-A | 
    | 2 | Web-server port forwarding on FW-b | Разрешение доступа из public сегмента к опубликованному в dmz сегменте приложению по порту TCP 8080 для FW-B | 
    | 3 | FW management & NLB healthcheck | Разрешение доступа к FW-A, FW-B, серверу управления FW из mgmt сегмента для задач управления и разрешение доступа к FW-A и FW-B для проверки состояний с помощью NLB healthcheck |
    | 4 | Stealth | Запрет доступа к FW-A, FW-B, серверу управления FW из других сегментов |
    | 5 | mgmt to DMZ | Разрешение доступа из mgmt сегмента к dmz сегменту для задач управления |
    | 6 | mgmt to app | Разрешение доступа из mgmt сегмента к app сегменту для задач управления |
    | 7 | mgmt to database | Разрешение доступа из mgmt сегмента к database сегменту для задач управления |
    | 8 | ping from dmz to internet | Разрешение ICMP пакетов из dmz сегмента в интернет для проверки работоспособности и тестирования отказоустойчивости |
    | 9 | Cleanup rule | Запрет доступа для остального трафика |

    </details>

    <details>
    <summary>Скриншот Access Control - Policy</summary>

    ![Access Control - Policy](./images/fw_access_control_policy.png)

    </details>

11. Настройте Static NAT трансляции. Source NAT трансляции обеспечивают прохождение ответа от приложения через тот же FW, через который поступил запрос от пользователя. Destination NAT трансляции направляют запросы пользователей на сетевой балансировщик трафика, за которым находится группа веб-серверов приложения.

    Заголовки пакетов, приходящих от ALB, с запросами от пользователей к опубликованному в dmz приложению будут транслироваться в Source IP dmz интерфейсов FW и в Destination IP балансировщика трафика для веб-серверов.

    | No | Original Source | Original Destination | Original Services | Translated Source | Translated Destination | Translated Services | Install On |
    | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- |
    | 1 | public | FW-a-public-IP | TCP_8080 | FW-a-dmz-IP (Hide) | dmz-web-server | Original | FW-a |
    | 2 | public | FW-b-public-IP | TCP_8080 | FW-b-dmz-IP (Hide) | dmz-web-server | Original | FW-b |

    <details>
    <summary>Скриншот Access Control - NAT</summary>

    ![Access Control - NAT](./images/nat.png)

    </details>    

12. **Обязательно примените настройки и политики на оба FW, используя Install Policy, чтобы они вступили в силу.**
    
    <details>
    <summary>Скриншот Install Policy</summary>

    ![Install Policy](./images/install_policy.png)

    </details> 


## Проверка работоспособности

1. Откройте в веб-браузере страницу `http://<Публичный_ip_адрес_балансировщика_ALB>`, который можно посмотреть в выводе команды `terraform output fw-alb_public_ip_address`. Должна открыться страница `Welcome to nginx!`

2. На рабочей станции, где запускалось развертывание Terraform, перейдите в папку с Terraform сценарием, подключитесь к одной из ВМ в dmz сегменте по SSH (замените IP адрес ВМ):
    ```bash
    ssh -i pt_key.pem admin@10.160.2.22
    ```

3. Запустите `ping` к ресурсу в интернет. Пинг должен успешно пройти в соответствие с разрешающим правилом `8. ping from dmz to internet` политики Access Control на FW:   
    ```bash
    ping ya.ru
    ```
    <details>
    <summary>Лог FW для разрешающего правила</summary>

    <img src="./images/log_accept.png" alt="Лог FW для разрешающего правила" width="600"/>

    </details> 

4. Запустите `ping` к Jump ВМ в mgmt сегменте. Пинг не проходит в соответствие с запрещающим правилом `9. Cleanup rule` политики Access Control на FW:
    ```bash
    ping 192.168.1.100
    ```

    <details>
    <summary>Лог FW для запрещающего правила</summary>

    <img src="./images/log_drop.png" alt="Лог FW для запрещающего правила" width="600"/>

    </details>

## Проверка отказоустойчивости

1. На рабочей станции, где запускался Terraform сценарий, установите утилиту `httping` для выполнения периодических http запросов к тестовому приложению. [Версия для Windows](https://github.com/pjperez/httping). [Версия для Linux](https://github.com/folkertvanheusden/HTTPing) устанавливается командой:
    ```bash
    sudo apt-get install httping
    ```

2. Запустите входящий трафик к опубликованному в dmz сегменте приложению с помощью `httping` к публичному IP адресу балансировщика ALB, который можно посмотреть в выводе команды `terraform output fw-alb_public_ip_address`:
    ```bash
    httping http://<Публичный_ip_адрес_балансировщика_ALB>
    ```

3. Подключитесь по SSH к одной из ВМ в dmz сегменте по SSH (замените IP адрес ВМ):
    ```bash
    ssh -i pt_key.pem admin@10.160.2.22
    ```

4. Установите пароль для пользователя `admin`:
    ```bash
    sudo passwd admin
    ```

5. В консоли Yandex Cloud измените параметры этой ВМ, добавив "Разрешить доступ к серийной консоли". Подключитесь к серийной консоли ВМ, введите логин `admin` и пароль из 4-го шага. 

6. Запустите исходящий трафик из dmz сегмента с помощью `ping` к ресурсу в интернете:
    ```bash
    ping ya.ru
    ```

7. В консоли Yandex Cloud в каталоге mgmt остановите ВМ `fw-a`, эмулируя отказ основного FW.

8. Наблюдайте за пропаданием пакетов httping и ping. После отказа FW-A может наблюдаться пропадание трафика в пределах 1 мин, после чего трафик должен восстановиться.

9. Проверьте, что для подсетей в каталоге dmz стала активной таблица маршрутизации через FW-B `dmz-b-rt`.

10. В консоли Yandex Cloud запустите ВМ `fw-a`, эмулируя восстановление основного FW. 

11. Наблюдайте за пропаданием пакетов httping и ping. После восстановления FW-A может наблюдаться пропадание трафика в пределах 1 мин, после чего трафик должен восстановиться.

12. Проверьте, что для подсетей в каталоге dmz стала активной таблица маршрутизации через FW-A `dmz-a-rt`.


## Требования к развертыванию в продуктивной среде

- Обязательно смените пароли, которые были переданы через сервис metadata в файлах: check-init...yaml:
    - Пароль SIC для связи FW и сервера управления FW
    - Пароль от графической консоли Check Point SmartConsole
    - Пароль пользователя admin в сервере управления FW (можно изменить через Gaia Portal)
- Сохраните private SSH ключ pt_key.pem в надежное место либо пересоздайте его отдельно от Terraform
- Удалите публичный адрес у Jump ВМ, если не планируете ей пользоваться
- Если планируете использовать Jump ВМ для подключения к сегменту управления с помощью VPN WireGuard, то измените ключи для WireGuard на Jump ВМ и рабочей станции администратора 
- Настройте Access Control политики и NAT в Check Point NGFW для вашей инсталляции
- Не назначайте публичные IP адреса на ВМ в сегментах, где используются таблицы маршрутизации через Check Point NGFW ([подробности](https://cloud.yandex.ru/docs/vpc/concepts/static-routes#internet-routes)). Исключением является mgmt сегмент управления, где в таблицах маршрутизации не используется default route `0.0.0.0/0`. 
- Выберите подходящую лицензию и образ для Check Point CloudGuard IaaS (смотрите раздел [Next-Generation Firewall](#next-generation-firewall))

## Удаление созданных ресурсов

Чтобы удалить ресурсы, созданные с помощью Terraform, выполните команду `terraform destroy`.

> **Внимание**
> 
> Terraform удалит все ресурсы, созданные в этом сценарии, **без возможности восстановления**: сети, подсети, виртуальные машины, балансировщики, каталоги и т.д.

Так как созданные ресурсы расположены в каталогах, то в качестве более быстрого способа удаления всех ресурсов можно использовать удаление всех каталогов через консоль Yandex Cloud с дальнейшим удалением файла `terraform.tfstate` из папки.