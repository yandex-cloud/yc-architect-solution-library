#!/bin/bash
#Lockbox and CertificateManager
IAM_TOKEN=$(curl -s -H Metadata-Flavor:Google http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/token | jq -r '.access_token ')
curl -sSL -H "Authorization: Bearer $IAM_TOKEN" "https://payload.lockbox.api.cloud.yandex.net/lockbox/v1/secrets/$LOCKBOX_ID/payload" | jq -r ".entries[].textValue" | base64 -d > ssh-key
chmod 600 ssh-key
curl -sSL -H "Authorization: Bearer $IAM_TOKEN" "https://data.certificate-manager.api.cloud.yandex.net/certificate-manager/v1/certificates/$CERT_ID:getContent" | jq -r ".certificateChain[]" > $CERT_ID.crt
#Dynamic Inventory
HOST_GROUPS=$(curl -sSL -H "Authorization: Bearer $IAM_TOKEN" "https://mks.api.cloud.yandex.net/managed-kubernetes/v1/clusters/$CLUSTER_ID/nodeGroups" | jq -r ".[] | .[].id")
INVENTORY="{\n  \"all\": {\n    \"children\": {"

for group in $HOST_GROUPS; do
    HOSTS=$(curl -sSL -H "Authorization: Bearer $IAM_TOKEN" "https://mks.api.cloud.yandex.net/managed-kubernetes/v1/nodes?nodeGroupId=$group" | jq -r ".[] | .[].cloudStatus.id")
    GROUP_IPS=()

    for host in $HOSTS; do
        IP=$(curl -sSL -H "Authorization: Bearer $IAM_TOKEN" "https://compute.api.cloud.yandex.net/compute/v1/instances/$host" | jq -r ".networkInterfaces[].primaryV4Address.address")
        GROUP_IPS+=(\"$IP\")
    done

    INVENTORY+="\n      \"$group\": {"
    INVENTORY+="\n        \"hosts\": {"

    for ip in "${GROUP_IPS[@]}"; do
        INVENTORY+="\n          $ip,"
    done

    INVENTORY="${INVENTORY%,}\n        }"
    INVENTORY+="\n      },"
done

INVENTORY="${INVENTORY%,}\n    }\n  }\n}"

echo -e "$INVENTORY" > inventory.json

