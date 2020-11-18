#!/usr/bin/env bash

set -o pipefail
set -o nounset
set -o errexit

# remove previous versions
yum remove -y \
  docker \
  docker-client \
  docker-client-latest \
  docker-common \
  docker-latest \
  docker-latest-logrotate \
  docker-logrotate \
  docker-selinux \
  docker-engine-selinux \
  docker-engine

# install dependencies
yum install -y \
  device-mapper-persistent-data \
  lvm2 \
  yum-utils

# install the docker ce repository
cat > /etc/yum.repos.d/docker.repo <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://download.docker.com/linux/centos/7/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg
EOF

# install docker
yum install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io

# ensure the directory is created
mkdir -p /etc/systemd/system/docker.service.d
mkdir -p /etc/docker

curl -sL -o /etc/docker/daemon.json https://raw.githubusercontent.com/awslabs/amazon-eks-ami/master/files/docker-daemon.json
chown root:root /etc/docker/daemon.json

# add an environment file
cat > /etc/systemd/system/docker.service.d/environment.conf <<EOF
[Service]
EnvironmentFile=/etc/environment
EOF

# enable container selinux boolean
setsebool container_manage_cgroup on

systemctl daemon-reload && systemctl enable docker
