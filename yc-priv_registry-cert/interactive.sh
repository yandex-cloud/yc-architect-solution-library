#!/bin/bash

echo "Здравствуйте! Укажите, пожалуйста, ID Вашего mk8s кластера. / Hello! Please, specify an ID of your mk8s cluster."
read CLUSTER_ID
echo "Укажите ID секрета в Lockbox, куда вы ранее сохраняли приватный ssh ключ. / Specify an ID of Lockbox secret where you store you SSH private key."
read LOCKBOX_ID
echo "Укажите ID сертификата в Yandex Certificate Manager. / Specify an ID of your certificate Yandex Certificate Manager."
read CERT_ID
echo "Укажите имя пользователя для подключения к нодам mk8s кластера. / Specify a username to connect to nodes of mk8s cluster."
read USR
echo "Укажите ID container registry. / Specify an ID of the container registry."
read REGISTRY
echo "Укажите адрес container registry, например, example.com:9000. / Specify an address of the container registry, e.g. example.com:9000."
read VM
echo "Укажите namespace в mk8s кластере для этого задания. / Specify a namespace in mk8s cluster for this job."
read NSPACE

#start of job.yaml
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: yc-image
  namespace: $NSPACE
spec:
  template:
    spec:
      containers:
      - name: yc-image
        image: cr.yandex/$REGISTRY/yc-image:1.0
        imagePullPolicy: Always
        env:
        - name: CLUSTER_ID
          value: "$CLUSTER_ID"
        - name: LOCKBOX_ID
          value: "$LOCKBOX_ID"
        - name: CERT_ID
          value: "$CERT_ID"
        - name: USR
          value: "$USR"
        - name: VM
          value: "$VM"
        command: ["/bin/bash", "-c"]
        args:
        - >
          /worker.sh &&
          ansible-playbook -i /inventory.json playbook.yaml -u $USR
      restartPolicy: Never
EOF
#end of job.yaml

while true; do
  JOB_STATUS=$(kubectl get jobs yc-image -n $NSPACE -o json | jq -r ".status.conditions[].type" 2>/dev/null)

  if [ "$JOB_STATUS" == "Complete" ]; then
    echo "Job completed."
    break
  else
    echo "Job is in progress. Please wait."; sleep 10
  fi
done

kubectl delete jobs yc-image -n $NSPACE
