# Восстановление дискового массива после сбоя одного из дисков.

Данное решение показывает возможность восстановления диска в RAID-1 массиве, собранном на 2х [NRD](https://cloud.yandex.ru/docs/compute/concepts/disk#nr-disks) дисках.\
Этот сценарий тестировался на Linux дистрибутиве **Ubuntu 20.04 LTS**.

## Условия для использования (prerequisities)

* существующая папка в Облаке
* установленный инструмент [YC](https://cloud.yandex.ru/docs/cli/quickstart)
* настроенный YC [профиль](https://cloud.yandex.ru/docs/cli/operations/authentication/service-account)

## Описание решения

В данном решении показано развертывание виртуальной машины с дисковым массивом RAID-1, собранном из 2х отдельных NRD дисков. При отказе одного из дисков в массиве, его можно восстановить (заменить на другой).  

## Использование

### Входные параметры [**variables.tf**](./variables.tf)
* `vm_name` - имя виртуальной машины
* `vm_zone` - название зоны доступности, в которой будет развертываться VM
* `vm_disk_size` - размер одного диска в Гб кратно 93Гб. Все диски будут создаваться одинакового размера
* `vm_image` - образ из которого будет развертываться VM

### Развертывание
1. Проверяем конфигурацию рабочего окружения YC в файле [**env-yc-prod.sh**](./env-yc-prod.sh).\
   Меняем имя профиля "prod" на нужный.

2. Активируем рабочее окружение\
    `$ source env-yc-prod.sh`

3. Инициализируем Terraform\
    `$ terraform init`

4. Развертываем виртуальную машину\
    `$ terraform apply`

5. Подключаемся к VM по SSH\
    `ssh admin@<vm-public-ip>`

6. Проверяем состояние дисков после развертывания\
    `$ lsblk --output NAME,TYPE,SIZE,UUID`
    ```bash
    NAME    TYPE  SIZE UUID
    vda     disk    3G
    ├─vda1  part    1M
    └─vda2  part    3G 82afb880-9c95-44d6-8df9-84129f3f2cd1
    vdb     disk   93G 218bebe2-0013-9764-de87-7d9c13eb15bc
    └─md100 raid1  93G 72e0d3ca-9c34-43d4-be49-77f6c2bf894c
    vdc     disk   93G 218bebe2-0013-9764-de87-7d9c13eb15bc
    └─md100 raid1  93G 72e0d3ca-9c34-43d4-be49-77f6c2bf894c
    ```

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

## Тестирование

### 1. Записываем тестовые данные
```bash
$ sudo -i
$ echo "test-1234567890-987654321-abcdefghiklmnopqrstuvwxyz" > /data/test.txt
$ cat /data/test.txt
$ sha1sum /data/test.txt # -> 1108f5f9021d4ba066da47debaa24aea28d8bc9b
```

### 2. Симулируем отказ одного из дисков в RAID массиве
`$ sudo mdadm --manage /dev/md100 --fail /dev/disk/by-id/virtio-nrd1`
```bash
mdadm: set /dev/disk/by-id/virtio-nrd1 faulty in /dev/md100
```

### 3. Проверяем состояние массива
`$ sudo mdadm --detail /dev/md100`
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

`$ sudo cat /proc/mdstat` # -> *Сбойный диск будет помечен как “(F)”*
```bash
Personalities : [raid1] 
md100 : active raid1 vdc[1] vdb[0](F)
      97451008 blocks super 1.2 [2/1] [_U]      
unused devices: <none>
```

### 4. Уточняем id отказавшего диска
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

### 5. Выводим отказавший диск из массива, используя его id!
`$ sudo mdadm --manage /dev/md100 --remove /dev/disk/by-id/virtio-nrd1`\
mdadm: hot removed /dev/disk/by-id/virtio-nrd1 from /dev/md100

### 6. Отключаем диск (nrd1) от VM c помощью YC CLI
`yc compute instance list`\
`yc compute instance detach-disk --name nrd-raid-test --disk-name nrd1`

### 7. Создаем новый NRD диск (nrd3) c помощью YC CLI
`yc compute disk create nrd3 --type network-ssd-nonreplicated --size 93 --zone ru-central1-a`

### 8. Подключаем новый диск (nrd3) к VM c помощью YC CLI
`yc compute instance attach-disk --name nrd-raid-test --disk-name nrd3 --device-name nrd3 --mode rw`

### 9. Проверяем, что VM видит новый диск (nrd3) после подключения
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

### 10. Копируем таблицу разделов с рабочего диска (nrd2) на только что созданный (nrd3)

`$ sudo sfdisk -d /dev/disk/by-id/virtio-nrd2 | sfdisk /dev/disk/by-id/virtio-nrd3`

### 11. Добавляем новый диск в массив

`$ sudo mdadm --manage /dev/md100 --add /dev/disk/by-id/virtio-nrd3`

### 12. Проверяем состояние массива после добавления диска

`$ sudo mdadm --detail /dev/md100`

`$ cat /proc/mdstat`

### 13. Проверяем целостность данных
```bash
cat /data/test.txt
sha1sum /data/test.txt # -> 1108f5f9021d4ba066da47debaa24aea28d8bc9b
```