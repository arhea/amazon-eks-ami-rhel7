
PACKER_VARIABLES := binary_bucket_name binary_bucket_region eks_version eks_build_date cni_plugin_version hardening_flag
VPC_ID := vpc-0e8cf1ce122b1b059
SUBNET_ID := subnet-0eddf1d7d0f9f9772
AWS_REGOIN := us-east-2

build:
	packer build \
		--var 'aws_region=$(AWS_REGOIN)' \
		--var 'vpc_id=$(VPC_ID)' \
		--var 'subnet_id=$(SUBNET_ID)' \
		$(foreach packerVar,$(PACKER_VARIABLES), $(if $($(packerVar)),--var $(packerVar)='$($(packerVar))',)) \
		./amazon-eks-node.json

build-1.15:
	$(MAKE) build eks_version=1.15.11 eks_build_date=2020-09-18

build-1.15-stig:
	$(MAKE) build eks_version=1.15.11 eks_build_date=2020-09-18 hardening_flag=stig

build-1.16:
	$(MAKE) build eks_version=1.16.13 eks_build_date=2020-09-18

build-1.16-stig:
	$(MAKE) build eks_version=1.16.13 eks_build_date=2020-09-18 hardening_flag=stig

build-1.17:
	$(MAKE) build eks_version=1.17.11 eks_build_date=2020-09-18

build-1.17-stig:
	$(MAKE) build eks_version=1.17.11 eks_build_date=2020-09-18 hardening_flag=stig

build-1.18:
	$(MAKE) build eks_version=1.18.8 eks_build_date=2020-09-18

build-1.18-stig:
	$(MAKE) build eks_version=1.18.8 eks_build_date=2020-09-18 hardening_flag=stig
