# Демонстрация Network Policy Cilium и Hubble
## Cilium
* Создайте кластер Managed Kubernetes v.1.19 c включенным туннельным режимом
* Запустить тестовое приложение. Схема ![picture alt]( https://docs.cilium.io/en/v1.9/_images/cilium_http_gsg.png)
```
kubectl create -f https://raw.githubusercontent.com/cilium/cilium/v1.9/examples/minikube/http-sw-app.yaml
```
* Посмотреть список cilium endpoints. Необходимо указать нужный pod cilium-xxxx
```
kubectl -n kube-system get pods -l k8s-app=cilium
kubectl -n kube-system exec cilium-XXXX -- cilium endpoint list 
```
* Проверить доступность Звезды Смерти
```
kubectl exec tiefighter -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing
kubectl exec xwing -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing
```
* Применить политику L4
```
kubectl apply -f sw_l3_l4_policy.yaml
```
* Проверить доступность Звезды Смерти
```
kubectl exec tiefighter -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing
kubectl exec xwing -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing
```
* Проверить доступность PUT запроса Звезды Смерти
```
kubectl exec tiefighter -- curl -s -XPUT deathstar.default.svc.cluster.local/v1/exhaust-port
```
* Применить политику L7
```
kubectl apply -f sw_l3_l4_l7_policy.yaml
```
* Проверить доступность Звезды Смерти разными типами запросов
```
kubectl exec tiefighter -- curl -s -XPUT deathstar.default.svc.cluster.local/v1/exhaust-port
kubectl exec tiefighter -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing
```
## Hubble

Выполним поиск событий по заданным фильтрам
```
   hubble observe --pod deathstar --protocol http --last 7
   hubble observe --pod deathstar --verdict DROPPED --last 7

```
* Очистка 
```
kubectl delete cnp rule1
kubectl delete -f https://raw.githubusercontent.com/cilium/cilium/v1.9/examples/minikube/http-sw-app.yaml
```



