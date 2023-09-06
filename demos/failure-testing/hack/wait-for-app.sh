#!/bin/sh

URL="$1"
if [ -z "$URL" ]; then
    echo "URL parameter required" >&2
    exit 1
fi 
WAIT_TIMEOUT=${WAIT_TIMEOUT:-1800}
SUCCESS_THRESHOLD=${SUCCESS_THRESHOLD:-5}

echo -n "Waiting for $URL to become available... "
start_ts=$(date +%s)
success_tries=0
while :; do 
    elapsed=$(( $(date +%s) - start_ts )); 
    if [ $elapsed -gt $WAIT_TIMEOUT ]; then
        echo "Fail"
        break 
    fi
    if curl -s -f -L -o /dev/null --max-time 10 "$URL"; then
        success_tries=$(( success_tries + 1 ))
        if [ $success_tries -ge $SUCCESS_THRESHOLD ]; then
            echo "OK, ${elapsed}s elapsed"
            break
        fi
    else
        success_tries=0
    fi
done

test $success_tries -ge $SUCCESS_THRESHOLD
