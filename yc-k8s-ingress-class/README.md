# ALB Ingress Class

This guide shows how to deploy two ingresses with ingressClass nginx and alb in the same cluster and route traffic through them to the one app deployment.

## Prerequirites

- yc installed and configured
- mK8S deployed in YC
- Fill variables in `app/alb-ing.yaml` and `app/nginx-ing.yaml`

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
helm install cert-manager --namespace cert-manager --version v1.11.0 jetstack/cert-manager

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

kubectl get svc -n nginx # copy External IP of nginx-ingress service
yc dns zone add-records your-zone --record  "*.nginx 60 A <EXT_IP>"

kubectl config set-context --current --namespace app
kubectl apply -f app/app.yaml
kubectl apply -f app/nginx-ing.yaml

curl https://app.nginx.example.com
```

### DNS Challenge Webhook

- Install [Cert-manager with CloudDNS ACME webhookubectl plugin](https://cloud.yandex.ru/marketplace/products/yc/cert-manager-webhook-yandex)

Or install manually

```bash
kubectl config set-context --current --namespace cert-manager

# Install DNS Challenge Webhookubectl if not installed yet
yc iam key create --service-account-name sa-admin --output sa-admin.json
kubectl create secret generic --from-file sa-admin.json

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
  secretName: alb-example-secret
  issuerRef:
    # The issuer created previously
    name: yc-clusterissuer
    kind: ClusterIssuer
  dnsNames:
    - app.alb.<DOMAIN>
EOF

kubectl get certificate # checkubectl that READY=True
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
yc dns zone add-records your-zone --record  "*.app 60 A <EXT_IP>"

curl https://app.alb.example.com
```
