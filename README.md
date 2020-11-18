# Amazon EKS Node for Red Hat Enterprise Linux 7

This repository builds on the Red Hat Enterprise Linux 7 AMI to add the Amazon EKS components. These components allow this node to be used by as a worker node in a self-managed or managed node group in an EKS cluster. As a design goal, this AMI functions the same way as the [EKS optimized AMI](https://github.com/awslabs/amazon-eks-ami).

*Disclaimer: his is not an official AMI from AWS or Red Hat and is not officially supported. The AMI is based on the official Red Hat image available through the AWS Marketplace.*

## Usage

Similar to the EKS Optimized AMI, this AMI is built using the same tooling.

```bash
packer build \
  -var 'eks_version=1.18.8' \
  -var 'eks_build_date=2020-09-18' \
  -var 'vpc_id=vpc-xxxxxxxxxxxxxxxxx' \
  -var 'subnet_id=subnet-xxxxxxxxxxxxxxxxx' \
  -var 'volume_size=100' \
  ./amazon-eks-node.json
```

| Parameter | Default | Supported | Description |
|-----------|---------|-----------|-------------|
| eks_version | `1.18.8` | Any major version supported by EKS | The major Kubernetes version that aligns to your EKS cluster. |
| eks_build_date | `2020-09-18` | The build date of the EKS platform, used to pull in the latest binaries. |
| vpc_id | | `vpc-xxxxxxxxxxxxxxxxx` | The ID of the VPC to place the Packer builder. |
| subnet_id | | `subnet-xxxxxxxxxxxxxxxxx` | The ID of the Subnet to place the Packer builder. |
| volume_size | `100` | Any whole number in Gb | The size of the secondary volume. |

To deploy an EKS cluster using these AMIs as part of a manage node group, use the follow eksctl cluster.yml file. You will need to replace the AMI ID, region, and cluster name in the metadata and bootstrap command with values to match your environment. This file also attaches the policy for SSM.

```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: rhel7
  region: us-east-2

vpc:
  clusterEndpoints:
    publicAccess: true
    privateAccess: true

cloudWatch:
  clusterLogging:
    enableTypes:
      - "audit"
      - "authenticator"

iam:
  withOIDC: true

managedNodeGroups:

  - name: ng-1
    ami: ami-079099b4e0e9b1c38
    instanceType: m5.xlarge
    minSize: 3
    desiredCapacity: 3
    maxSize: 6
    privateNetworking: true
    labels:
      role: worker
    iam:
      attachPolicyARNs:
        - arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM
    ssh:
      allow: true
      publicKeyPath: ~/.ssh/id_rsa.pub
    overrideBootstrapCommand: |
      /etc/eks/bootstrap.sh rhel7 --kubelet-extra-args '--node-labels=eks.amazonaws.com/nodegroup=ng-1,eks.amazonaws.com/nodegroup-image=ami-079099b4e0e9b1c38'
    tags:
      k8s.io/cluster-autoscaler/enabled: "true"
      k8s.io/cluster-autoscaler/rhel7: "true"

```

## Disk Layout

The resulting images consists of two disks, a root disk and a secondary disk. The secondary disk is used to add the required partitions to meet CIS Benchmark requirements.

| Disk | Mount Point | % of Secondary Volume Size | Description |
|------|-------------|----------------------------|-------------|
| `/dev/nvme0n1p1` |`/` | 20% | This is the root disk used by the EKS optimized AMI. |
| `/dev/nvme1n1p1` | `/var` | 20% | A separate partition for `/var` as required by the CIS Benchmark. |
| `/dev/nvme1n1p2` | `/var/log` | 20% | A separate partition for `/var/log` as required by the CIS Benchmark. |
| `/dev/nvme1n1p3` | `/var/log/audit` | 20% | A separate partition for `/var/log/audit` as required by the CIS Benchmark. |
| `/dev/nvme1n1p4` | `/home` | 10% | A separate partition for `/home` as required by the CIS Benchmark. |
| `/dev/nvme1n1p5` | `/var/lib/docker` | 30% | A separate partition for `/var/lib/docker` as required by the CIS Benchmark. |

## License

This library is licensed under the MIT-0 License. See the [LICENSE file](./LICENSE).
