#!/usr/bin/env bash

set -o pipefail
set -o nounset
set -o errexit

# wait for cloud-init to finish
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 5; done

# upgrade the operating system
yum update -y && yum autoremove -y

# enable repositories
yum-config-manager --enable rhel-7-server-rhui-rpms
yum-config-manager --enable rhel-7-server-rhui-rh-common-rpms
yum-config-manager --enable rhel-7-server-rhui-extras-rpms

# install dependencies
yum install -y ca-certificates curl yum-utils audit audit-libs parted unzip

# enable audit log
systemctl enable auditd && systemctl start auditd

# enable the /etc/environment
touch /etc/environment

# install aws cli
curl -s -o awscli-bundle.zip https://s3.amazonaws.com/aws-cli/awscli-bundle.zip
unzip awscli-bundle.zip -d ./
./awscli-bundle/install -i /usr/local/aws -b /usr/bin/aws
rm -f awscli-bundle.zip

# install ssm agent
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent
