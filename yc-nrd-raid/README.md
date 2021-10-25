# Восстановление дискового массива после сбоя одного из дисков.

Данное решение показывает возможность восстановления диска в RAID-1 массиве, собранном на 2х [NRD](https://cloud.yandex.ru/docs/compute/concepts/disk#nr-disks) дисках.

Этот сценарий тестировался на Linux дистрибутиве **Ubuntu 20.04 LTS**. 

Процедура восстановления диска по шагам описана в разделе [Восстановление диска](#dr)

## Условия для использования (prerequisities)

* существующая папка в Облаке
* установленный инструмент [YC CLI](https://cloud.yandex.ru/docs/cli/quickstart)
* настроенный YC [профиль](https://cloud.yandex.ru/docs/cli/operations/authentication/service-account)

В данном решении показано развертывание виртуальной машины с дисковым массивом RAID-1, собранном из 2х отдельных NRD дисков. При отказе одного из дисков в массиве, его можно восстановить (заменить на другой).  

## Идентификаторы и имена устройств.
Замена отказавшего диска это ответственный процесс, в котором очень важно не ошибиться с объектом воздействия и по неосторожности удалить данные не там где хотелось. Для исключения подобных ситуаций рекомендуется **всегда** работать с дисками через их идентификаторы `device-id`, и не использовать для таких операций имена устройств, например, */dev/vdb*. 

Идентификаторы дисков `device-id` могут выглядеть по разному внутри VM. Если при создании диска с помощью YC CLI был указан ключ **--device-name nrd2**, то именно это имя и будет являться частью device-id внутри виртуальной машины, например, "virtio-nrd2" (см. вывод ниже). Если же ключ **--device-name** не использовался при создании диска, то device-id виртуальной машины будет выглядеть по другому - "virtio-fhmjrhl1vjv8p2j68cm8" (см. вывод ниже).

Идентификаторы устройств обычно уникальны, а имена устройств могут динамически меняться в случаях добавления и удаления устройств.

Чтобы посмотреть связь между device-id и device-name можно воспользоваться командой: `ls -l /dev/disk/by-id/`. Ниже приведен пример вывода этой команды.

`$ ls -l /dev/disk/by-id/`
```bash
lrwxrwxrwx 1 root root 11 Oct 15 11:30 md-name-nrd-raid-test:100 -> ../../md100
lrwxrwxrwx 1 root root 11 Oct 15 11:30 md-uuid-c4ba6e99:0b18df98:5dc8a734:ac8a6d48 -> ../../md100
lrwxrwxrwx 1 root root  9 Oct 15 11:29 virtio-fhmjrhl1vjv8p2j68cm8 -> ../../vda
lrwxrwxrwx 1 root root 10 Oct 15 11:29 virtio-fhmjrhl1vjv8p2j68cm8-part1 -> ../../vda1
lrwxrwxrwx 1 root root 10 Oct 15 11:29 virtio-fhmjrhl1vjv8p2j68cm8-part2 -> ../../vda2
lrwxrwxrwx 1 root root  9 Oct 15 11:30 virtio-nrd1 -> ../../vdb
lrwxrwxrwx 1 root root  9 Oct 15 11:30 virtio-nrd2 -> ../../vdc 
```

## Рекомендации по созданию нереплицируемых дисков (NRD) в Яндекс.Облаке
* [Нереплицируемые SSD-диски](https://cloud.yandex.ru/docs/compute/concepts/disk) (network-ssd-nonreplicated) — это сетевой диск с повышенной производительностью.
* При создании NRD дисков через Terraform или YC CLI всегда задавать параметр device-name, в котором указывать понятное вам имя диска.
* Для повышния отказоустойчивости дисковой подсистемы, для NRD дисков рекомндуется использовать [группы размещения](https://cloud.yandex.ru/docs/compute/concepts/disk-placement-group), которые размещают диски в разных стойках ЦОД.


## Развертывание VM и симуляция отказа диска

### План развертывания
  1. [Создаем группу размещения дисков](https://cloud.yandex.ru/docs/compute/operations/disk-placement-groups/create)
  2. [Создаем нереплицируемые диски в группе размещения](https://cloud.yandex.ru/docs/compute/operations/disk-create/nonreplicated#nr-disk-in-group)
  3. [Создаем VM и подключаем к ней созданные NRD диски](https://cloud.yandex.ru/docs/compute/operations/vm-create/create-linux-vm)

В качестве примера для развертывания можно использовать подготовленный terraform код ниже.

### Развертывание VM с помощью Terraform

#### Задать параметры развертывания в [**variables.tf**](./variables.tf)
* `vm_name` - имя виртуальной машины
* `vm_zone` - название зоны доступности, в которой будет развертываться VM
* `vm_disk_size` - размер одного диска в Гб кратно 93Гб. Все диски будут создаваться одинакового размера
* `vm_image` - образ из которого будет развертываться VM

#### Запустить развертывание
1. Проверяем конфигурацию рабочего окружения YC в файле [**env-yc-prod.sh**](./env-yc-prod.sh).\
   Меняем имя профиля "prod" на нужный.

2. Активируем рабочее окружение\
    `source env-yc-prod.sh`

3. Инициализируем Terraform\
    `terraform init`

4. Развертываем виртуальную машину\
    `terraform apply`

5. Подключаемся к VM по SSH\
    `ssh admin@<vm-public-ip>`

6. Проверяем состояние дисков после развертывания\
    `$ ls -l /dev/disk/by-id/`
    ```bash
    md-name-nrd-raid-test:100                   -> ../../md100
    md-uuid-663a720f:b0c8ab74:be2d83ae:70677d6d -> ../../md100
    virtio-fhmni7jprp8264t8i5mg                 -> ../../vda
    virtio-fhmni7jprp8264t8i5mg-part1           -> ../../vda1
    virtio-fhmni7jprp8264t8i5mg-part2           -> ../../vda2
    virtio-nrd1                                 -> ../../vdb
    virtio-nrd2                                 -> ../../vdc
    ```

    `$ sudo mdadm --query /dev/md100`
      ```bash
      /dev/md100: 92.94GiB raid1 2 devices, 0 spares. Use mdadm --detail for more detail.
      ```

    `$ sudo mdadm --detail /dev/md100`
      ```bash
      /dev/md100:
                Version  : 1.2
          Creation Time  : Sun Oct 10 16:14:26 2021
              Raid Level : raid1
              Array Size : 97451008 (92.94 GiB 99.79 GB)
          Used Dev Size  : 97451008 (92.94 GiB 99.79 GB)
            Raid Devices : 2
          Total Devices  : 2
            Persistence  : Superblock is persistent

            Update Time  : Sun Oct 10 16:30:37 2021
                  State  : clean
          Active Devices : 2
        Working Devices  : 2
          Failed Devices : 0
          Spare Devices  : 0

      Consistency Policy : resync

                    Name : nrd-raid-test:100 (local to host nrd-raid-test)
                    UUID : 663a720f:b0c8ab74:be2d83ae:70677d6d
                  Events : 29

          Number   Major   Minor   RaidDevice State
            0     252       16        0      active sync   /dev/vdb
            1     252       32        1      active sync   /dev/vdc
      ```

7. Записываем тестовые данные на диск
```bash
$ sudo -i
$ echo "test-1234567890-987654321-abcdefghiklmnopqrstuvwxyz" > /data/test.txt
$ cat /data/test.txt
$ sha1sum /data/test.txt # -> 1108f5f9021d4ba066da47debaa24aea28d8bc9b
```

### Симулируем отказ одного из дисков в RAID массиве
В нашем примере мы используем два диска, собранные в один [RAID-1](https://ru.wikipedia.org/wiki/RAID#RAID_1) массив. Такой массив обеспечивает полную сохранность данных в случае выхода из строя одного из дисков. Для быстрого восстановления уровня отказоустойчивости массива после сбоя одного из дисков необходима его замена.

Чтобы быстро узнавать о такого рода проблемах рекомендуется настраивать Мониторинг и уведомления, например, на электронную почту. 

На практике, перед тем как выполнять какие-то операции с диском, необходимо понимать его состояние. Нормально работащий диск должен находится в состоянии "READY" (поле status). Состояние диска можно оценить с помощью команды YC CLI, указав в ней id диска как аргумент. Например, `yc compute disk get fhmd0e91sfmksudo9io4`. Результат выполнения команды:
```yml
id: fhmd0e91sfmksudo9io4
folder_id: u1g32j0789iog4d3cnk3
created_at: "2021-10-16T11:53:12Z"
name: nrd1
type_id: network-ssd-nonreplicated
zone_id: ru-central1-a
size: "99857989632"
block_size: "4096"
status: READY
disk_placement_policy:
  placement_group_id: fhm26q5eq2341rgbmhgs
```

`$ sudo mdadm --manage /dev/md100 --fail /dev/disk/by-id/virtio-nrd1`
```bash
mdadm: set /dev/disk/by-id/virtio-nrd1 faulty in /dev/md100
```

## Восстановление диска <a id="dr"/>

  1. [Проверяем состояние дискового массива](#dr-1)
  2. [Проверяем device-id отказавшего диска](#dr-2)
  3. [Выводим отказавший диск из массива](#dr-3)
  4. [Получаем список групп размещения дисков](#dr-4)
  5. [Определяем группу размещения для отказавшего диска](#dr-5)
  6. [Отключаем отказавший диск от VM](#dr-6)
  7. [Создаем новый NRD диск](#dr-7)
  8. [Подключаем новый диск к VM](#dr-8)
  9. [Проверяем доступность нового диска после подключения](#dr-9)
  10. [Копируем таблицу разделов с рабочего диска на новый](#dr-10)
  11. [Добавляем новый диск в RAID массив](#dr-11)
  12. [Проверяем состояние массива после добавления диска](#dr-12)
  13. Проверяем целостность данных


### 1. Проверяем состояние дискового массива <a id="dr-1"/>

```bash
/dev/md100:
           Version : 1.2
     Creation Time : Mon Oct 11 15:50:12 2021
        Raid Level : raid1
        Array Size : 97451008 (92.94 GiB 99.79 GB)
     Used Dev Size : 97451008 (92.94 GiB 99.79 GB)
      Raid Devices : 2
     Total Devices : 2
       Persistence : Superblock is persistent

       Update Time : Tue Oct 12 09:18:37 2021
             State : clean, degraded 
    Active Devices : 1
   Working Devices : 1
    Failed Devices : 1
     Spare Devices : 0

Consistency Policy : resync

              Name : nrd-raid-test:100  (local to host nrd-raid-test)
              UUID : b64eb7cd:6c0c1924:872fe4c0:bb5487c8
            Events : 23

    Number   Major   Minor   RaidDevice State
       -       0        0        0      removed
       1     252       32        1      active sync   /dev/vdc
       0     252       16        -      faulty        /dev/vdb
```

`$ sudo cat /proc/mdstat`
```bash
Personalities : [raid1] 
md100 : active raid1 vdc[1] vdb[0](F)
      97451008 blocks super 1.2 [2/1] [_U]      
unused devices: <none>
```
Сбойный диск будет помечен как "`(F)`"


### 2. Проверяем device-id отказавшего диска <a id="dr-2"/> 
  `$ ls -l /dev/disk/by-id/`

    ```bash
    md-name-nrd-raid-test:100 -> ../../md100
    md-uuid-9a5e8799:5d6db030:e7c959c2:38ce99ce -> ../../md100
    virtio-fhm8rsgmrjc9vmi1kj85 -> ../../vda
    virtio-fhm8rsgmrjc9vmi1kj85-part1 -> ../../vda1
    virtio-fhm8rsgmrjc9vmi1kj85-part2 -> ../../vda2
    virtio-nrd1 -> ../../vdb
    virtio-nrd2 -> ../../vdc
    ```

### 3. Выводим отказавший диск из массива <a id="dr-3"/> 
Выводим отказавший диск из массива, используя его device-id

`$ sudo mdadm --manage /dev/md100 --remove /dev/disk/by-id/virtio-nrd1`
```bash
mdadm: hot removed /dev/disk/by-id/virtio-nrd1 from /dev/md100
```

### 4. Получаем список групп размещения дисков <a id="dr-4"/> 
`yc compute disk-placement-group list`
```bash
+----------------------+------+---------------+--------+
|          ID          | NAME |     ZONE      | STATUS |
+----------------------+------+---------------+--------+
| fhm26q5eq2341rgbmhgs |      | ru-central1-a | READY  |
+----------------------+------+---------------+--------+
```

### 5. Определяем группу размещения для отказавшего диска <a id="dr-5"/> 
Смотрим диски в каждой группе размещения пока не найдем сбойный диск. Фиксируем id группы размещения.

`yc compute disk-placement-group list-disks --id fhm26q5eq2341rgbmhgs`
```bash
+----------------------+------+-------------+---------------+--------+----------------------+-------------+
|          ID          | NAME |    SIZE     |     ZONE      | STATUS |     INSTANCE IDS     | DESCRIPTION |
+----------------------+------+-------------+---------------+--------+----------------------+-------------+
| fhmd0e91sfmksudo9io4 | nrd1 | 99857989632 | ru-central1-a | READY  | fhmtfc9ggo2qc6ude23e |             |
| fhmidi40rdmj4km5u9vd | nrd2 | 99857989632 | ru-central1-a | READY  | fhmtfc9ggo2qc6ude23e |             |
+----------------------+------+-------------+---------------+--------+----------------------+-------------+
```

### 6. Отключаем отказавший диск от VM <a id="dr-6"/> 
`yc compute instance list`
```bash
+----------------------+---------------+---------------+---------+-----------------+-------------+
|          ID          |     NAME      |    ZONE ID    | STATUS  |   EXTERNAL IP   | INTERNAL IP |
+----------------------+---------------+---------------+---------+-----------------+-------------+
| fhmtfc9ggo2qc6ude23e | nrd-raid-test | ru-central1-a | RUNNING | 62.84.119.106   | 10.128.0.29 |
+----------------------+---------------+---------------+---------+-----------------+-------------+
```
`yc compute instance detach-disk nrd-raid-test --disk-id fhmd0e91sfmksudo9io4`
```yml
done (11s)
id: fhmtfc9ggo2qc6ude23e
folder_id: b1g44j0674iog4o3ovh7
created_at: "2021-10-16T11:53:17Z"
name: nrd-raid-test
zone_id: ru-central1-a
platform_id: standard-v1
resources:
  memory: "4294967296"
  cores: "2"
  core_fraction: "100"
status: RUNNING
boot_disk:
  mode: READ_WRITE
  device_name: fhmvcmo4p8gs8vu99k0r
  auto_delete: true
  disk_id: fhmvcmo4p8gs8vu99k0r
secondary_disks:
- mode: READ_WRITE
  device_name: nrd2
  disk_id: fhmidi40rdmj4km5u9vd
network_interfaces:
- index: "0"
  mac_address: d0:0d:1d:7b:13:08
  subnet_id: e9bkhb79tegftff4tfqf
  primary_v4_address:
    address: 10.128.0.29
    one_to_one_nat:
      address: 62.84.119.106
      ip_version: IPV4
fqdn: nrd-raid-test.ru-central1.internal
scheduling_policy: {}
network_settings:
  type: STANDARD
placement_policy: {}
```

### 7. Создаем новый NRD диск <a id="dr-7"/> 
Создаем новый NRD диск (nrd3) и помещаем его в уже существующую группу размещения.

`yc compute disk create nrd3 \`\
`--type network-ssd-nonreplicated \`\
`--size 93 --zone ru-central1-a \`\
`--disk-placement-group-id fhm26q5eq2341rgbmhgs`
```yml
done (5s)
id: fhmlnioblb9co9pill3e
folder_id: b1g44j0674iog4o3ovh7
created_at: "2021-10-17T07:04:38Z"
name: nrd3
type_id: network-ssd-nonreplicated
zone_id: ru-central1-a
size: "99857989632"
block_size: "4096"
status: READY
disk_placement_policy:
  placement_group_id: fhm26q5eq2341rgbmhgs
```

### 8. Подключаем новый диск к VM <a id="dr-8"/> 
`yc compute instance attach-disk --name nrd-raid-test --disk-name nrd3 --device-name nrd3 --mode rw`
```yml
done (3s)
id: fhmtfc9ggo2qc6ude23e
folder_id: b1g44j0674iog4o3ovh7
created_at: "2021-10-16T11:53:17Z"
name: nrd-raid-test
zone_id: ru-central1-a
platform_id: standard-v1
resources:
  memory: "4294967296"
  cores: "2"
  core_fraction: "100"
status: RUNNING
boot_disk:
  mode: READ_WRITE
  device_name: fhmvcmo4p8gs8vu99k0r
  auto_delete: true
  disk_id: fhmvcmo4p8gs8vu99k0r
secondary_disks:
- mode: READ_WRITE
  device_name: nrd2
  disk_id: fhmidi40rdmj4km5u9vd
- mode: READ_WRITE
  device_name: nrd3
  disk_id: fhmlnioblb9co9pill3e
network_interfaces:
- index: "0"
  mac_address: d0:0d:1d:7b:13:08
  subnet_id: e9bkhb79tegftff4tfqf
  primary_v4_address:
    address: 10.128.0.29
    one_to_one_nat:
      address: 62.84.119.106
      ip_version: IPV4
fqdn: nrd-raid-test.ru-central1.internal
scheduling_policy: {}
network_settings:
  type: STANDARD
placement_policy: {}
```

### 9. Проверяем доступность нового диска после подключения <a id="dr-9"/> 
`$ ls -l /dev/disk/by-id/`

  ```bash
  md-name-nrd-raid-test:100 -> ../../md100
  md-uuid-9a5e8799:5d6db030:e7c959c2:38ce99ce -> ../../md100
  virtio-fhm8rsgmrjc9vmi1kj85 -> ../../vda
  virtio-fhm8rsgmrjc9vmi1kj85-part1 -> ../../vda1
  virtio-fhm8rsgmrjc9vmi1kj85-part2 -> ../../vda2
  virtio-nrd2 -> ../../vdc
  virtio-nrd3 -> ../../vdb
  ```

### 10. Копируем таблицу разделов с рабочего диска на новый <a id="dr-10"/> 
`$ sudo sfdisk -d /dev/disk/by-id/virtio-nrd2 | sudo sfdisk /dev/disk/by-id/virtio-nrd3`
```bash
Checking that no-one is using this disk right now ... OK

Disk /dev/disk/by-id/virtio-nrd3: 93 GiB, 99857989632 bytes, 195035136 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: dos
Disk identifier: 0x00000000

Old situation:

Device                            Boot Start       End   Sectors Size Id Type
/dev/disk/by-id/virtio-nrd3-part1          1 195035135 195035135  93G ee GPT

Partition 1 does not start on physical sector boundary.

>>> Script header accepted.
>>> Script header accepted.
>>> Script header accepted.
>>> Script header accepted.
>>> Created a new DOS disklabel with disk identifier 0x00000000.
/dev/disk/by-id/virtio-nrd3-part1: Created a new partition 1 of type 'GPT' and of size 93 GiB.
/dev/disk/by-id/virtio-nrd3-part2: Done.

New situation:
Disklabel type: dos
Disk identifier: 0x00000000

Device                            Boot Start       End   Sectors Size Id Type
/dev/disk/by-id/virtio-nrd3-part1          1 195035135 195035135  93G ee GPT

Partition 1 does not start on physical sector boundary.

The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.
```

### 11. Добавляем новый диск в RAID массив <a id="dr-11"/> 
`$ sudo mdadm --manage /dev/md100 --add /dev/disk/by-id/virtio-nrd3`
```bash
mdadm: added /dev/disk/by-id/virtio-nrd3
```

### 12. Проверяем состояние массива после добавления диска <a id="dr-12"/> 
`$ sudo mdadm --detail /dev/md100`
```bash
/dev/md100:
           Version : 1.2
     Creation Time : Sat Oct 16 11:54:57 2021
        Raid Level : raid1
        Array Size : 97451008 (92.94 GiB 99.79 GB)
     Used Dev Size : 97451008 (92.94 GiB 99.79 GB)
      Raid Devices : 2
     Total Devices : 2
       Persistence : Superblock is persistent

       Update Time : Sun Oct 17 07:12:14 2021
             State : clean, degraded, recovering
    Active Devices : 1
   Working Devices : 2
    Failed Devices : 0
     Spare Devices : 1

Consistency Policy : resync

    Rebuild Status : 11% complete

              Name : nrd-raid-test:100  (local to host nrd-raid-test)
              UUID : 95f26a09:a7e89ebf:65dac840:815cb020
            Events : 27

    Number   Major   Minor   RaidDevice State
       2     252       16        0      spare rebuilding   /dev/vdb
       1     252       32        1      active sync   /dev/vdc
```

`$ cat /proc/mdstat`
```bash
Personalities : [raid1]
md100 : active raid1 vdb[2] vdc[1]
      97451008 blocks super 1.2 [2/1] [_U]
      [===>.................]  recovery = 15.8% (15470464/97451008) finish=13.4min speed=101943K/sec

unused devices: <none>
```
Нв выводах команд выше видно, что идет процесс восстановления (rebuild/recovery) дискового массива.
После завершения процесса восстановления выводы команд должны стать такими:

`$ sudo mdadm --detail /dev/md100`
```bash
/dev/md100:
           Version : 1.2
     Creation Time : Sat Oct 16 11:54:57 2021
        Raid Level : raid1
        Array Size : 97451008 (92.94 GiB 99.79 GB)
     Used Dev Size : 97451008 (92.94 GiB 99.79 GB)
      Raid Devices : 2
     Total Devices : 2
       Persistence : Superblock is persistent

       Update Time : Sun Oct 17 07:27:16 2021
             State : clean
    Active Devices : 2
   Working Devices : 2
    Failed Devices : 0
     Spare Devices : 0

Consistency Policy : resync

              Name : nrd-raid-test:100  (local to host nrd-raid-test)
              UUID : 95f26a09:a7e89ebf:65dac840:815cb020
            Events : 43

    Number   Major   Minor   RaidDevice State
       2     252       16        0      active sync   /dev/vdb
       1     252       32        1      active sync   /dev/vdc
```

`$ cat /proc/mdstat`
```bash
Personalities : [raid1]
md100 : active raid1 vdb[2] vdc[1]
      97451008 blocks super 1.2 [2/2] [UU]

unused devices: <none>
```
### 13. Проверяем целостность данных

