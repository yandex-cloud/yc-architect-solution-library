// Folder id for resources
folder_id = "b1gentmqf1ve9uc54nfh"

// List of trusted public IP addresses for connection to NAT-instances 
trusted_ip_for_mgmt = ["A.A.A.A/32", "B.B.B.0/24"]

// List of trusted cloud internal networks for connection to Object Storage through NAT-instances"
trusted_cloud_nets = ["10.0.0.0/8"]

// Username for VMs
vm_username = "admin"

// Number of NAT instances for Instance group
nat_instances_count = "4"

// List of Yandex Cloud availability zones for deploying NAT instances
yc_availability_zones = [
    "ru-central1-a",
    "ru-central1-b"
]