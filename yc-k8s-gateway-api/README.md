# Gateway API usecases for Managed Kubernetes

This folder contains examples of k8s manifests to set up kubernetes [gateways](https://gateway-api.sigs.k8s.io/) for Prod and Dev environments. Environments placed to different namespaces. Gateways configured to be bind only to particular namespaces for isolation. TLS secrets placed to separate namespace.

## Prerequires

- Managed Kubernetes Cluster in Yandex Cloud.
- Installed and initialized [yc cli](https://cloud.yandex.com/en-ru/docs/cli/operations/install-cli).
- Public domain [deletated to Cloud DNS](https://cloud.yandex.com/en-ru/docs/dns/concepts/dns-zone#public-zones) service by Yandex Cloud.

## Gateway installation

- Install Gateway API from Marketplace. In console go to Managed Service for Kubernetes -> (Select your cluster) -> Marketplace -> Gateway API -> Use.
- Fill all necessary fields and install Gateway API.

## Example of Prod and Dev gateways and environments

### Create reserved IP addresses

```bash
yc vpc address create --name=prod --labels reserved=true --external-ipv4 zone=ru-central1-b # change to zone of your cluster
yc vpc address create --name=dev --labels reserved=true --external-ipv4 zone=ru-central1-b # change to zone of your cluster
```

### Create prod and dev records to your zone

```bash
yc dns zone add-records --name yc-courses --record '*.prod.example.com 60 A  <ip_address>'
yc dns zone add-records --name yc-courses --record '*.dev.example.com 60 A  <ip_address>'
```

### Create tls certificate (optional) and separate namespace for tls secrets

Create separate namespace for tls secrets.

```bash
kubectl create namespace gateway-api-tls-secrets
```

Create certificate for prod gateway.

```bash
openssl req -x509 \
    -newkey rsa:4096 \
    -keyout gateway-key-prod.pem \
    -out gateway-cert-prod.pem \
    -nodes \
    -days 365 \
    -subj '/CN=*.prod.example.com'

kubectl create -n gateway-api-tls-secrets secret tls gateway-prod-tls \
    --cert=gateway-cert-prod.pem \
    --key=gateway-key-prod.pem
```

Create certificate for dev gateway.

```bash
openssl req -x509 \
    -newkey rsa:4096 \
    -keyout gateway-key-dev.pem \
    -out gateway-cert-dev.pem \
    -nodes \
    -days 365 \
    -subj '/CN=*.dev.example.com'

kubectl create -n gateway-api-tls-secrets secret tls gateway-dev-tls \
    --cert=gateway-cert-dev.pem \
    --key=gateway-key-dev.pem
```

### Configure your IP adresses and domains

Replace <ip_address> in yaml files to real IPs created earlier and change example.com to your domains.

### Apply manifests

```bash
kubectl apply prod-gw.yaml
kubectl apply prod-app.yaml
kubectl apply prod-route.yaml

kubectl apply dev-gw.yaml
kubectl apply dev-app.yaml
kubectl apply dev-route.yaml
```

### Check applications

Check applications on `app.prod.example.com` and `app.dev.example.com`.
