#!/bin/sh

manifest="$1"
START_AFTER="${2:-300s}"
STOP_AFTER="$3"
harm_running=0

trap "trapfunc" SIGTERM SIGINT

trapfunc() {
    test $harm_running -ne 0 || return
    echo "$(date): Removing harm manifest $manifest"
    kubectl delete -f "$manifest"
}

if [ -z "$manifest" ]; then 
    echo "Manifest parameter missing" >&2
    exit 1
fi

if [ ! -f "$manifest" ]; then 
    echo "Manifest file not found ($manifest)" >&2
    exit 1
fi

if [ $HARM_ENABLED -eq 1 ]; then
    echo "$(date): Waiting $START_AFTER before apply harm"
    sleep $START_AFTER
    echo "$(date): Applying harm manifest $manifest"
    harm_running=1
    kubectl apply -f $manifest
    if [ -n "$STOP_AFTER" ]; then
        echo "$(date): Waiting $STOP_AFTER before removing harm"
        sleep $STOP_AFTER
        echo "$(date): Removing harm manifest $manifest"
        kubectl delete -f $manifest
        harm_running=0
    fi
else
    echo "$(date): Harm skipped"
fi

echo "$(date): Waiting until shutdown"
tail -f /dev/null 

