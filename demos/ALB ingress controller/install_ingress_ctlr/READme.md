# Install Y.Application Load Balancer Ingress Controller
* Create service account in yandex cloud and grant editor permission for the folder where ALB load balancer for cluster ingresses will be created:
```
yc iam service-account create --name k8s-alb-ingress --folder-id <FOLDER_ID>

id: <SERVICE_ACCOUNT_ID>

yc resource-manager folder add-access-binding --role editor --subject:serviceAccount<SERVICE_ACCOUNT_ID> <FOLDER_ID>


yc iam key create --service-account-id <SERVICE_ACCOUNT_ID> --output sa-key.json
```
* Create namaspace and secret
```
kubectl create namespace yc-alb-ingress

kubectl create secret generic -n yc-alb-ingress yc-alb-ingress-controller-sa-key --from-file=sa-key.json=sa-key.json
```
* Edit values in `config.yaml` with your **FOLDER_ID** and **SUBNET_IDs**
* Apply ingress controller manifests:

```
kubectl apply -f .
```
* Verify ingress controller POD is **RUNNING**