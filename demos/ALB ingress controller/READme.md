# Демонстрация Y.Application Load Balancer Ingress Controller
## Установить Y.Application Load Balancer Ingress Controller
Выполнить [инструкцию по установке](./install_ingress_ctlr/READme.md)
## Требования для получения сертификата Let's Encrypt
* Создать публичную [DNS зону в CloudDNS](https://cloud.yandex.ru/docs/dns/operations/zone-create-public). Чтобы получить доступ к именам из публичной зоны, вам нужно делегировать домен. Укажите адреса серверов ns1.yandexcloud.net и ns2.yandexcloud.net в личном кабинете вашего регистратора.
* В сервисе Y.Cetification Manager [запросить wildcard сертификат Let's Encrypt](https://cloud.yandex.ru/docs/certificate-manager/operations/managed/cert-create) на Ваш домен. 
## Использование самоподписанного сертификата
Так же можно использовать имеющийся или [самоподписанный](https://cloud.yandex.ru/docs/certificate-manager/operations/import/cert-create) из папки [/nrkcert](./nrkcert)

## Выполнение сценария

* Замените в файле ingress.yaml значение: 
  ```
  TLS: hosts: xxxx.xx
    secretName: yc-certmgr-cert-id-xxxxxxxxxxx
  rules: host: xxxx.xx
  ```
  
  Well-known значение TLS:secretName -  **yc-certmgr-cert-id-xxxxxxxxxxx** используется для привязки сертификата из Y.Cetification Manager
* Создайте объекты приложений и Ingress 
  ```
  kubectl apply -f .
  ```
* Дождитесь создания ingress и получения им IP адреса

  ```
  Kubectl get ingress alb-demo-tls
  ```
* Выполните проверочные запросы к полученному IP адресу ingress, заменив `"Host: "` при необходимости

  ```
  curl https://84.252.132.XXX/app1  -H "Host: nginx.demo.nrk.me.uk" -k
  curl https://84.252.132.XXX/app2  -H "Host: nginx.demo.nrk.me.uk" -k

  ```
* Перейдите в консоль Yandex.Cloud в раздел Application Load Balancer и ознакомьтесь с созданными объектами.
* Очистка 
  ```
  kubectl delete -f .
  ```