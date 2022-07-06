---
apiVersion: vpc.yandex-cloud.jet.crossplane.io/v1alpha1
kind: Network
metadata:
  name: $NET_NAME
  annotations:
    crossplane.io/external-name: $NET_ID
spec:
  deletionPolicy: Orphan
  forProvider:
    name: $NET_NAME
    folderId: $FOLDER_ID

---
apiVersion: vpc.yandex-cloud.jet.crossplane.io/v1alpha1
kind: Subnet
metadata:
  name: $NET_NAME-$ZONE_ID
  annotations:
    crossplane.io/external-name: $SUBNET_ID
spec:
  deletionPolicy: Orphan
  forProvider:
    name: $NET_NAME-$ZONE_ID
    networkIdRef:
      name: $NET_NAME
    v4CidrBlocks:
      - $SUBNET_PREFIX
    zone: $ZONE_ID
    folderId: $FOLDER_ID

---
apiVersion: compute.yandex-cloud.jet.crossplane.io/v1alpha1
kind: Instance
metadata:
  name: $VM_NAME
spec:
  forProvider:
    name: $VM_NAME
    platformId: standard-v2
    zone: $ZONE_ID
    resources:
      - cores: 2
        memory: 4
    bootDisk:
      - initializeParams:
          # LEMP stack
          # yc compute image get --folder-id standard-images --name=lemp-v20220606 --format=json | jq -r .id
          - imageId: $IMAGE_ID
    networkInterface:
      - subnetIdRef:
          name: $NET_NAME-$ZONE_ID
    folderId: $FOLDER_ID
 