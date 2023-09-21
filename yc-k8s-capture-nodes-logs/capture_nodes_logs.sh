#!/bin/bash
##
## DESCRIPTION
##      Capture logs from node(s) of k8s cluster
##      The selection of data for capture is based on the modification time of files with logs
##      Collecting logs requires permission to get a list of cluster nodes via kubectl
##      
## OPTIONS
##      Node_Name    - Node name for capture logs
##                     If ($Node_Name == "All") or ($# -eq 0) 
##                     then capture logs from all nodes
##
##      Logs_Since   - Capture logs since that time
##                     Default value - start of the current date
##
## USAGE
##      capture_nodes_logs.sh [Node_Name] [Logs_Since]
##  
## EXAMPLES
##      Get logs from all node
##      ./capture_nodes_logs.sh 
##
##      Get logs from node cl12cdps8ti4t7qlhuq0-ygif
##      ./capture_nodes_logs.sh cl12cdps8ti4t7qlhuq0-ygif
##
##      Get logs from all nodes since 2023-05-26 10:00:00
##      ./capture_nodes_logs.sh ALL "2023-05-26 10:00:00"
##
## IMPLEMENTATION
##      version         1.0.0
##      author          Andrey Ulrikh
##      copyright       Copyright (c) http://yandex.ru
##
## HISTORY
##      2023/05/26  : andrey-ulrikh : Script creation

# Set default value for Logs_Since argument
LogsSince="$(date +%F) 00:00:00"

if [[ $# -gt 0 ]]; then
  if [[ $(echo $1 | tr A-Z a-z) == "all" ]]; then
    kubectl get no -o name | cut -c 6- > list.node
  else
    echo "$1" > list.node
  fi   
  if [[ $# -gt 1 ]]; then
    LogsSince="$2"
  fi
else
  kubectl get no -o name | cut -c 6-  > list.node
fi

for NodeName in $(cat list.node); do
  echo
  mkdir $NodeName
  kubectl debug node/$NodeName --image=cr.yandex/yc/mk8s-openssl:stable -- sleep 600
  PodName=$(kubectl get po -o name | grep $NodeName | cut -c 5-)
  echo -n "Pod <$PodName> creating."
  while [[ $(kubectl get pods "${PodName}" -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo -n "." && sleep 1; done

  echo -e "done\nGet syslog modified after $LogsSince"
  kubectl exec $PodName -- find /host/var/log -type f -newermt "${LogsSince}" -name "syslog*" -execdir echo {} ';' | cut -c 3- >list.logs
  for file in $(cat list.logs); do kubectl cp default/"${PodName}":host/var/log/$file $NodeName/$file; done

  echo -n "Detect folder with CSI logs - "
  CSI_Logs=host/var/log/pods/$(kubectl exec $PodName -- ls /host/var/log/pods | grep "kube-system_yc-disk-csi-node-v2")/yc-disk-csi-driver
  echo $CSI_Logs
  echo Get tar-file with SCI logs modified after $LogsSince
  kubectl exec $PodName -- find /$CSI_Logs -newermt "${LogsSince}" -name "*.log" -execdir echo {} ';' | cut -c 3- >list.logs
  if [ -s list.logs ]; then
    for file in $(cat list.logs); do kubectl exec $PodName -- tar fr /$CSI_Logs/csi_logs.tar -C /$CSI_Logs $file; done
    kubectl cp default/"${PodName}":$CSI_Logs/csi_logs.tar csi_logs.tar
    echo Extract CSI log files
    tar xf csi_logs.tar -C ./$NodeName
  else
    echo "There are no SCI logs for the specified interval"
  fi
  echo Delete temp objects on the node
  kubectl exec $PodName -- rm /$CSI_Logs/csi_logs.tar
  kubectl delete po $PodName
done

echo Remove all local temp files
rm csi_logs.tar
rm list.logs
rm list.node
