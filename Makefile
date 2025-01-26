# Global Variables
PACKER_CMD = packer build
TEMPLATE_DIR = templates
VARIABLE_DIR = variables

# Build targets for each provider
.PHONY: build-alicloud build-aws build-azure build-bare-metal build-digital-ocean build-gcp build-hetzner build-huawei build-linode build-ovh build-tencent build-all

# Build targets for each provider
build-alicloud:
    $(PACKER_CMD) -var-file=alicloud/$(VARIABLE_DIR)/alicloud.pkrvars.hcl alicloud/$(TEMPLATE_DIR)/alicloud.pkr.hcl

build-aws:
	$(PACKER_CMD) -var-file=aws/$(VARIABLE_DIR)/aws.pkrvars.hcl aws/$(TEMPLATE_DIR)/aws.pkr.hcl

build-azure:
	$(PACKER_CMD) -var-file=azure/$(VARIABLE_DIR)/azure.pkrvars.hcl azure/$(TEMPLATE_DIR)/azure.pkr.hcl

build-bare-metal:
    $(PACKER_CMD) -var-file=bare-metal/$(VARIABLE_DIR)/bare-metal.pkrvars.hcl bare-metal/$(TEMPLATE_DIR)/bare-metal.pkr.hcl

build-digital-ocean:
    $(PACKER_CMD) -var-file=digital-ocean/$(VARIABLE_DIR)/digital-ocean.pkrvars.hcl digital-ocean/$(TEMPLATE_DIR)/digital-ocean.pkr.hcl

build-gcp:
	$(PACKER_CMD) -var-file=gcp/$(VARIABLE_DIR)/gcp.pkrvars.hcl gcp/$(TEMPLATE_DIR)/gcp.pkr.hcl

build-hetzner:
    $(PACKER_CMD) -var-file=hetzner/$(VARIABLE_DIR)/hetzner.pkrvars.hcl hetzner/$(TEMPLATE_DIR)/hetzner.pkr.hcl

build-huawei:
    $(PACKER_CMD) -var-file=huawei/$(VARIABLE_DIR)/huawei.pkrvars.hcl huawei/$(TEMPLATE_DIR)/huawei.pkr.hcl

build-linode:
    $(PACKER_CMD) -var-file=linode/$(VARIABLE_DIR)/linode.pkrvars.hcl linode/$(TEMPLATE_DIR)/linode.pkr.hcl

build-ovh:
    $(PACKER_CMD) -var-file=ovh/$(VARIABLE_DIR)/ovh.pkrvars.hcl ovh/$(TEMPLATE_DIR)/ovh.pkr.hcl

build-tencent:
    $(PACKER_CMD) -var-file=tencent/$(VARIABLE_DIR)/tencent.pkrvars.hcl tencent/$(TEMPLATE_DIR)/tencent.pkr.hcl

# Build targets for mai/sub and all
build-main: build-alicloud build-aws build-azure build-gcp build-tencent

build-sub: build-bare-metal build-digital-ocean build-hetzner build-huawei build-linode build-ovh

build-all: build-alicloud build-aws build-azure build-bare-metal build-digital-ocean build-gcp build-hetzner build-huawei build-linode build-ovh build-tencent
