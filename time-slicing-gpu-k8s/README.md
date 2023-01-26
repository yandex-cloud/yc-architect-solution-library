# Time-Slicing GPUs in Kubernetes
## Intro

The NVIDIA [GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/overview.html) allows **oversubscription of GPUs** through a set of extended options for the NVIDIA Kubernetes Device Plugin. Internally, GPU time-slicing is used to allow workloads that land on oversubscribed GPUs to interleave with one another. This page covers ways to enable this in Managed service for Kubernetes using the GPU Operator.

This mechanism for enabling “time-sharing” of GPUs in Kubernetes allows a system administrator to define a set of “replicas” for a GPU, each of which can be handed out independently to a pod to run workloads on. Unlike [MIG](https://www.google.com/url?q=https://docs.google.com/document/d/1mdgMQ8g7WmaI_XVVRrCvHPFPOMCm5LQD5JefgAh6N8g/edit&sa=D&source=editors&ust=1655578433019961&usg=AOvVaw1F-OezvM-Svwr1lLsdQmu3)(Multi-Instance GPU), there is no memory or fault-isolation between replicas, but for some workloads this is better than not being able to share at all. Internally, GPU time-slicing is used to multiplex workloads from replicas of the same underlying GPU.

Official [documentation](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/gpu-sharing.html#configuration-for-shared-access-to-gpus-with-gpu-time-slicing)

## Quick start


[Add node group](https://cloud.yandex.ru/docs/managed-kubernetes/operations/node-group/node-group-create) with NVIDIA T4 GPU

Provide time-slicing configurations for the NVIDIA Kubernetes Device Plugin as a ConfigMap:
```
kubectl create -f time-slicing-config.yaml
```
Install GPU Operator
```
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia \
   && helm repo update \
   && helm install gpu-operator nvidia/gpu-operator \
     -n gpu-operator \
     --set devicePlugin.config.name=time-slicing-config
```
If u use one type of GPU across the cluster, you can use default: 
```
kubectl patch clusterpolicies.nvidia.com/cluster-policy \
   -n gpu-operator --type merge \
   -p '{"spec": {"devicePlugin": {"config": {"name": "time-slicing-config", "default": "tesla-t4"}}}}'

```
Testing GPU Time-Slicing with the NVIDIA GPU Operator

Create a deployment with multiple replicas:
```
kubectl apply -f nvidia-plugin-test.yml
```
Verify that all five replicas are running:
```
kubectl get pods
```
Check nvidia-smi
```
kubectl exec <nvidia-container-toolkit-name> -n gpu-operator -- nvidia-smi
```
Your output should look something like this:
```

Defaulted container "nvidia-container-toolkit-ctr" out of: nvidia-container-toolkit-ctr, driver-validation (init)
Thu Jan 26 09:42:51 2023       
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 515.65.01    Driver Version: 515.65.01    CUDA Version: N/A      |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|                               |                      |               MIG M. |
|===============================+======================+======================|
|   0  Tesla T4            Off  | 00000000:8B:00.0 Off |                    0 |
| N/A   72C    P0    70W /  70W |   1579MiB / 15360MiB |    100%      Default |
|                               |                      |                  N/A |
+-------------------------------+----------------------+----------------------+
                                                                               
+-----------------------------------------------------------------------------+
| Processes:                                                                  |
|  GPU   GI   CI        PID   Type   Process name                  GPU Memory |
|        ID   ID                                                   Usage      |
|=============================================================================|
|    0   N/A  N/A     43108      C   /usr/bin/dcgmproftester11         315MiB |
|    0   N/A  N/A     43211      C   /usr/bin/dcgmproftester11         315MiB |
|    0   N/A  N/A     44583      C   /usr/bin/dcgmproftester11         315MiB |
|    0   N/A  N/A     44589      C   /usr/bin/dcgmproftester11         315MiB |
|    0   N/A  N/A     44595      C   /usr/bin/dcgmproftester11         315MiB |
+-----------------------------------------------------------------------------+
```