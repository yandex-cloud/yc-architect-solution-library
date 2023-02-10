#!/bin/bash

REPO="https://raw.githubusercontent.com/yandex-cloud/yc-architect-solution-library/master/drawio-terraform"

TARGET=drawio-tf-example
mkdir -p $TARGET

FILES="env-yc.sh $TARGET/env-yc.sh
providers.tf $TARGET/providers.tf
compute.tf $TARGET/compute.tf
drawio.tf $TARGET/drawio.tf
variables.tf $TARGET/variables.tf
vm-drawio.tpl $TARGET/vm-drawio.tpl"


echo "$FILES" | while read URL FILE; 
do 
  curl -sl "$REPO/$URL" -o "$FILE"
done
