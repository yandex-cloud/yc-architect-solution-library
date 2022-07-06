import os
import pulumi
import pulumi_yandex as yc

# Create new network in VPC
vpc_network = yc.VpcNetwork("pulumi-net")

# Parse environment variables
access_key = os.environ["SA_KEY"]
secret_key = os.environ["SA_SECRET"]
bucket_name = os.environ["BUCKET"]

# Create bucket at the Object Storage
bucket = yc.StorageBucket("pulumi_bucket",
    access_key=access_key,
    secret_key=secret_key,
    bucket=bucket_name)
