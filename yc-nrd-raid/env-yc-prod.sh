echo "YC environment -> PROD"
unset YC_ENDPOINT
yc config profile activate prod
export YC_TOKEN=$(yc iam create-token)
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)
