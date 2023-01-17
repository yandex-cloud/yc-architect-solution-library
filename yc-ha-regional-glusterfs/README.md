# Glusterfs

Guide how to make distributed HA storage based on GlusterFS

## Getting started

```bash
yc config profile activate <your profile>  
./env-yc-prod.sh
```

### Terraform

```bash
make init
vi variables.tf
# choose default values for variables
make apply

# use output to access publically available first client
ssh storage@<IP_addr_of_client>
```

### GlusterFS installation

```bash
# client
sudo -i

dnf install epel-release -y
dnf install clustershell -y
echo 'ssh_options: -oStrictHostKeyChecking=no' >> /etc/clustershell/clush.conf

cat > /etc/clustershell/groups.conf <<'EOF'
[Main]
default: cluster
confdir: /etc/clustershell/groups.conf.d $CFGDIR/groups.conf.d
autodir: /etc/clustershell/groups.d $CFGDIR/groups.d
EOF

cat > /etc/clustershell/groups.d/cluster.yaml <<EOF
cluster:
    all: '@clients,@gluster'
    clients: 'client[01-03]'
    gluster: 'gluster[01-03]'
EOF

clush -w @all hostname # check and auto add fingerprints
clush -w @all dnf install centos-release-gluster -y
clush -w @all dnf --enablerepo=powertools install glusterfs-server -y
clush -w @gluster mkfs.xfs -f -i size=512 /dev/vdb
clush -w @gluster mkdir -p /bricks/brick1
clush -w @gluster "echo '/dev/vdb /bricks/brick1 xfs defaults 1 2' >> /etc/fstab"
clush -w @gluster "mount -a && mount"

clush -w @gluster systemctl enable glusterd
clush -w @gluster systemctl restart glusterd

clush -w gluster01 gluster peer probe gluster02
clush -w gluster01 gluster peer probe gluster03
clush -w @gluster mkdir -p /bricks/brick1/vol0

# High-Available Gluster Cluster with erasure coding 2 + 1
clush -w gluster01 gluster volume create regional-volume disperse 3 redundancy 1 gluster01:/bricks/brick1/vol0 gluster02:/bricks/brick1/vol0 gluster03:/bricks/brick1/vol0 # HA 

# Additional performance tuning
clush -w gluster01 gluster volume set regional-volume client.event-threads 8
clush -w gluster01 gluster volume set regional-volume server.event-threads 8
clush -w gluster01 gluster volume set regional-volume cluster.shd-max-threads 8
clush -w gluster01 gluster volume set regional-volume performance.read-ahead-page-count 16
clush -w gluster01 gluster volume set regional-volume performance.client-io-threads on
clush -w gluster01 gluster volume set regional-volume performance.quick-read off 
clush -w gluster01 gluster volume set regional-volume performance.parallel-readdir on 
clush -w gluster01 gluster volume set regional-volume performance.io-thread-count 32
clush -w gluster01 gluster volume set regional-volume performance.cache-size 1GB
clush -w gluster01 gluster volume set regional-volume server.allow-insecure on   

# Start volume
clush -w gluster01  gluster volume start regional-volume

# Check volumes status
clush -w gluster01  gluster volume status

# Mount volume to clients
clush -w @clients mount -t glusterfs gluster01:/regional-volume /mnt/

# Create random file on first client
cat /dev/urandom | tr -dc '[:alnum:]' > /mnt/urandom.file

# Check hashsum on all clients
clush -w @clients sha256sum /mnt/urandom.file
# client01: 83a76155d74a67c59934fb984d025e6b787c8748345ef5317f096c8ba8ea7530  /mnt/urandom.file
# client02: 83a76155d74a67c59934fb984d025e6b787c8748345ef5317f096c8ba8ea7530  /mnt/urandom.file
# client03: 83a76155d74a67c59934fb984d025e6b787c8748345ef5317f096c8ba8ea7530  /mnt/urandom.file
```

### HA testing

1. Poweroff storage node in zone (if there is one node per zone)
1. Check file availability

```bash
sha256sum /mnt/urandom.file
# ca2a89d5925b50552ddf4a4da2773091e8f9ecc879d148577a59d0c25bbec781  /mnt/urandom.file

gluster volume status
# Status of volume: regional-volume
# Gluster process                             TCP Port  RDMA Port  Online  Pid
# ------------------------------------------------------------------------------
# Brick gluster01:/bricks/brick1/vol0         50545     0          Y       5629
# Brick gluster02:/bricks/brick1/vol0         52270     0          Y       5498
# Self-heal Daemon on localhost               N/A       N/A        Y       8076
# Self-heal Daemon on gluster01.ru-central1.i
# nternal                                     N/A       N/A        Y       5645
# Self-heal Daemon on gluster02               N/A       N/A        Y       5514

# Task Status of Volume regional-volume
# ------------------------------------------------------------------------------
# There are no active volume tasks

```
