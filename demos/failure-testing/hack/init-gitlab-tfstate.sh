#!/bin/bash

if [ -f ~/.chaos ]; then
    . ~/.chaos
fi

GITLAB_STATE_NAME=${GITLAB_STATE_NAME:-default}

read -p "GitLab root URL [$GITLAB_URL]: " _tmp
GITLAB_URL=${_tmp:-$GITLAB_URL}
test -n "$GITLAB_URL" || { echo "GITLAB_URL must be defined"; exit 1; }

read -p "project ID [$GITLAB_PROJECT_ID]: " _tmp
GITLAB_PROJECT_ID=${_tmp:-$GITLAB_PROJECT_ID}
test -n "$GITLAB_PROJECT_ID" || { echo "GITLAB_PROJECT_ID must be defined"; exit 1; }

read -p "username [$GITLAB_USERNAME]: " _tmp
GITLAB_USERNAME=${_tmp:-$GITLAB_USERNAME}
test -n "$GITLAB_USERNAME" || { echo "GITLAB_USERNAME must be defined"; exit 1; }

read -p "access token:" -s _tmp && echo
GITLAB_ACCESS_TOKEN=${_tmp:-$GITLAB_ACCESS_TOKEN} 
test -n "$GITLAB_ACCESS_TOKEN" || { echo "GITLAB_ACCESS_TOKEN must be defined"; exit 1; }

read -p "Press <enter> to proceed to create terraform state (ctrl-c to abort)" _tmp

GITLAB_URL=$(echo "$GITLAB_URL" | sed 's,/+$,,g')

base_url="$GITLAB_URL/api/v4/projects/$GITLAB_PROJECT_ID/terraform/state/$GITLAB_STATE_NAME"

terraform init -reconfigure \
    -backend-config="address=$base_url" \
    -backend-config="lock_address=$base_url/lock" \
    -backend-config="unlock_address=$base_url/lock" \
    -backend-config="username=$GITLAB_USERNAME" \
    -backend-config="password=$GITLAB_ACCESS_TOKEN" \
    -backend-config="lock_method=POST" \
    -backend-config="unlock_method=DELETE" \
    -backend-config="retry_wait_min=5"
