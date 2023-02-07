//-------------id for cloud in Yandex Cloud
cloud_id = "b1g8dn6s3v2eiid9dbci"

//-------------TCP port used for public application published in DMZ
public_app_port = "80" 
//-------------and corresponding internal port for the same application
internal_app_port = "8080"

//-------------Define list of trusted public IP addresses for connection to Jump VM 
trusted_ip_for_access_jump-vm = ["A.A.A.A/32", "B.B.B.0/24"]

//-------------Jump VM Wireguard settings
wg_port = "51820" 
wg_client_dns = "192.168.1.2, 192.168.2.2"
jump_vm_admin_username = "admin"

//------------VPC List
//--VPC 1-- DMZ
vpc_name_1 = "demo-dmz"
subnet-a_vpc_1 = "10.160.1.0/24" 
subnet-b_vpc_1 = "10.160.2.0/24" 
//--VPC 2-- app
vpc_name_2 = "demo-app" 
subnet-a_vpc_2 = "10.161.1.0/24" 
subnet-b_vpc_2 = "10.161.2.0/24"
//--VPC 3-- public
vpc_name_3 = "demo-public"
subnet-a_vpc_3 = "172.16.1.0/24" 
subnet-b_vpc_3 = "172.16.2.0/24" 
//--VPC 4-- management
vpc_name_4 = "demo-mgmt"
subnet-a_vpc_4 = "192.168.1.0/24" 
subnet-b_vpc_4 = "192.168.2.0/24" 
//--VPC 5-- database
vpc_name_5 = "demo-database"
subnet-a_vpc_5 = "10.162.1.0/24"
subnet-b_vpc_5 = "10.162.2.0/24" 

//-----------Additional VPC List (for the future because you can't add interfaces after VM creation)
//--VPC 6--
vpc_name_6 = "demo-vpc6"
subnet-a_vpc_6 = "10.163.1.0/24" 
subnet-b_vpc_6 = "10.163.2.0/24" 
//--VPC 7--
vpc_name_7 = "demo-vpc7"
subnet-a_vpc_7 = "10.164.1.0/24"
subnet-b_vpc_7 = "10.164.2.0/24"
//--VPC 8--
vpc_name_8 = "demo-vpc8"
subnet-a_vpc_8 = "10.165.1.0/24"
subnet-b_vpc_8 = "10.165.2.0/24"