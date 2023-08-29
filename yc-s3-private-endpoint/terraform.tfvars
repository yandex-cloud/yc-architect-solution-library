// Folder id for resources
folder_id = "b1gentmqf1ve9uc54nfh"

// List of Yandex Cloud availability zones for deploying NAT instances
yc_availability_zones = [
    "ru-central1-a",
    "ru-central1-b"
]

// Number of NAT instances 
nat_instances_count = 4

// Restrict access to bucket only from NAT-instances public IP-address
bucket_private_access = true

// Allow access to bucket from Yandex Cloud console, apply if bucket_private_access = true
bucket_console_access = true

// Public IP address of Terraform workstation to allow access in bucket policy
mgmt_ip = "A.A.A.A"

// List of trusted cloud internal networks for connection to Object Storage through NAT-instances"
trusted_cloud_nets = ["10.0.0.0/8"]

// Username for VMs
vm_username = "admin"