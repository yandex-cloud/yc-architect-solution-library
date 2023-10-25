# ALB Ingress Class

This guide shows how to deploy two ingresses with ingressClass nginx and alb in the same cluster and route traffic through them to the one app deployment.

## Prerequirites

- yc installed and configured
- Public zone for your [delegated](https://cloud.yandex.com/en-ru/docs/dns/operations/zone-create-public?from=int-console-help-center-or-nav) domain
- mK8S deployed in YC
- Fill variables in `app/alb-ing.yaml` and `app/nginx-ing.yaml`

```bash
git clone https://github.com/yc-architect-solution-library
cd yc-architect-solution-library/yc-k8s-ingress-class
```

## NGINX ingress + cert-manager.io Installation

```bash
kubectl create ns nginx
kubectl create ns app

# NGINX Ingress
kubectl config set-context --current --namespace nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx

# Cert-manager
# ! Install Cert-Manager + YC DNS Webhookubectl from MP
# OR install Cert-Manager manually
helm repo add jetstackubectl https://charts.jetstack.io
helm repo update
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.crds.yaml
helm install cert-manager --namespace cert-manager --create-namespace --version v1.11.0 jetstack/cert-manager

# Configure ClusterIssuer
kubectl apply -f -<<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
  namespace: cert-manager
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: <EMAIL>
    privateKeySecretRef:
      name: letsencrypt
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

kubectl get svc -n nginx
NAME                                 TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                      AGE
ingress-nginx-controller             LoadBalancer   10.96.145.247   84.201.163.76   80:31668/TCP,443:30353/TCP   6d12h # copy External IP of nginx-ingress-nginx-controller service
ingress-nginx-controller-admission   ClusterIP      10.96.200.103   <none>          443/TCP                      6d12h


yc dns zone add-records your-zone  --record  "*.nginx.<DOMAIN>. 60 A <EXT_IP>"
yc dns zone list-records your-zone

+-------------------------+------+------+--------------------------------+
|          NAME           | TTL  | TYPE |              DATA              |
+-------------------------+------+------+--------------------------------+
| *.nginx.example.com.    |   60 | A    | <EXT_IP>                       |
| example.com.            | 3600 | NS   | ns1.yandexcloud.net.           |
|                         |      |      | ns2.yandexcloud.net.           |
| example.com.            | 3600 | SOA  | ns1.yandexcloud.net.           |
|                         |      |      | mx.cloud.yandex.net. 1 10800   |
|                         |      |      | 900 604800 900                 |
+-------------------------+------+------+--------------------------------+


kubectl config set-context --current --namespace app


kubectl apply -f app/demo-app1.yaml && kubectl apply -f app/demo-app2.yaml
kubectl apply -f app/nginx-ing.yaml

# Checking that everything is working properly
curl https://app.nginx.<DOMAIN>
curl https://app.nginx.<DOMAIN>/app1
curl https://app.nginx.<DOMAIN>/app2
App by Ingress Class
```

### DNS Challenge Webhook

- Install [Cert-manager with CloudDNS ACME webhookubectl plugin](https://cloud.yandex.ru/marketplace/products/yc/cert-manager-webhook-yandex)

Or install manually

```bash
kubectl config set-context --current --namespace cert-manager

# Install DNS Challenge Webhookubectl if not installed yet
yc iam key create --service-account-name sa-admin --output sa-admin.json
kubectl create secret generic cert-manager-secret --from-file=sa-admin.json

git clone https://github.com/yandex-cloud/cert-manager-webhook-yandex.git && \
helm install -n cert-manager yandex-webhookubectl \
  cert-manager-webhook-yandex/deploy/cert-manager-webhook-yandex

# Create clusterIssuer with DNS challenge
kubectl apply -f -<<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: yc-clusterissuer
spec:
  acme:
    # You must replace this email address with your own.
    # Let's Encrypt will use this to contact you about expiring
    # certificates, and issues related to your account.
    email: <EMAIL>
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      # Secret resource that will be used to store the account's private key.
      name: secret-ref
    solvers:
      - dns01:
          webhook:
            config:
              # The ID of the folder where dns-zone located in
              folder: <FOLDERID>
              # This is the secret used to access the service account
              serviceAccountSecretRef:
                name: cert-manager-secret
                key: sa-admin.json
            groupName: acme.cloud.yandex.com
            solverName: yandex-cloud-dns
EOF

# Create certififcate
kubectl apply -f -<<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: alb-example
spec:
  secretName: example-com-secret
  issuerRef:
    # The issuer created previously
    name: yc-clusterissuer
    kind: ClusterIssuer
  dnsNames:
    - app.alb.<DOMAIN>
EOF

kubectl get certificate # check that the status READY=True. It might take some time.
```

### ALB Ingress Class Installation

- Install [ALB Ingress Controller](https://cloud.yandex.ru/marketplace/products/yc/alb-ingress-controller) from MP (follow the instructions)

Then do:

```bash
kubectl config set-context --current --namespace alb
kubectl apply -f alb-ingress-class.yaml # apply ALB ingressClass definition

kubectl config set-context --current --namespace app
kubectl apply -f app/alb-ing.yaml 

kubectl get svc # copy External IP of alb-ingress service
yc dns zone add-records your-zone  --record  "*.alb.<DOMAIN>. 60 A <EXT_IP>"
yc dns zone list-records your-zone

+-------------------------+------+------+--------------------------------+
|          NAME           | TTL  | TYPE |              DATA              |
+-------------------------+------+------+--------------------------------+
| *.alb.example.com.      |   60 | A    | <EXT_IP>                       |
| *.nginx.example.com.    |   60 | A    | <EXT_IP>                       |
| example.com.            | 3600 | NS   | ns1.yandexcloud.net.           |
|                         |      |      | ns2.yandexcloud.net.           |
| example.com.            | 3600 | SOA  | ns1.yandexcloud.net.           |
|                         |      |      | mx.cloud.yandex.net. 1 10800   |
|                         |      |      | 900 604800 900                 |
+-------------------------+------+------+--------------------------------+

# Checking that everything is working properly
curl https://app.alb.<DOMAIN>
curl https://app.alb.<DOMAIN>/app1
curl https://app.alb.<DOMAIN>/app2
```