.ONESHELL:

.PHONY: default
default: prepare-vm

UBUNTU_VERSION ?= jammy
YAML_PARSER := ./utils/parse_yaml.sh
CONFIG_FILE := ./config.yml
VMRUN_SCRIPT :=./vm-runner/vmrun
CLOUD_INIT_DIR := ./cloud-init/
TEMP_FILE := /tmp/make_vars.mk
AWK := awk
CURL := curl -L -o
QEMU_IMG := qemu-img


#This parses yml config file and includes variables 
include $(shell bash -c 'source $(YAML_PARSER); parse_yaml $(CONFIG_FILE) > $(TEMP_FILE); echo $(TEMP_FILE)')

PROJECT_NAME = $(if $(strip $(project_name)),$(strip $(subst ",,$(project_name))),k3)
PROJECT_DIR := $(CURDIR)
VM_DIR := $(if $(strip $(vm_dir)),$(strip $(subst ",,$(vm_dir))),./vm/)
BASE_IMAGE := $(VM_DIR)$(PROJECT_NAME).qcow2
SNAPSHOT_IMAGE := $(VM_DIR)$(PROJECT_NAME)_snapshot.qcow2
SNAPSHOT_IMAGE_NAME := $(PROJECT_NAME)_snapshot.qcow2
CLOUD_INIT_ISO := $(CLOUD_INIT_DIR)cloud-init.iso
USER_DATA := $(CLOUD_INIT_DIR)user-data
USER_DATA_YAML := $(CLOUD_INIT_DIR)user-data.yaml
USER_DATA_MERGET := $(CLOUD_INIT_DIR)user-data-merged.yaml
GRAFANA_CONTENT := \#GRAFANA_CONTENT
GRAFANA_YAML := $(CLOUD_INIT_DIR)grafana.yaml

DIRECTORIES := $(VM_DIR) $(CLOUD_INIT_DIR) 

IMAGE_URL_BASE = https://cloud-images.ubuntu.com/$(UBUNTU_VERSION)/current
IMAGE_NAME := $(UBUNTU_VERSION)-server-cloudimg-amd64.img

HOSTPORT = $(if $(strip $(hostport)),$(hostport),8022)
VMPORT = $(if $(strip $(vmport)),$(vmport),22)
CPUS = $(if $(strip $(cpus)),$(cpus),2)
RAM = $(if $(strip $(ram)),$(ram),4G)
DISK_SIZE = $(if $(strip $(disksize)),$(disksize),200G)

IMG_FORMAT = qcow2
IMAGES = \
    $(VM_DIR)disk1.qcow2 \
    $(VM_DIR)disk2.qcow2 \
    $(VM_DIR)disk3.qcow2 \
	$(VM_DIR)disk4.qcow2

disk1_SIZE = $(DISK_SIZE)
disk2_SIZE = $(DISK_SIZE)
disk3_SIZE = $(DISK_SIZE)
disk4_SIZE = $(DISK_SIZE)

define launcher =
#!/bin/bash 
PROJECT_NAME=$(PROJECT_NAME) RAM=$(RAM) CPUS=$(CPUS) HOSTPORT=$(HOSTPORT) VMPORT=$(VMPORT) VM_DIR=$(VM_DIR) $(VMRUN_SCRIPT) -c ./config.yml $$1
endef

.PHONY: check-tools
check-tools:
	@command -v $(CURL) >/dev/null 2>&1 || { echo "$(CURL) is required but not installed."; exit 1; }
	@command -v $(QEMU_IMG) >/dev/null 2>&1 || { echo "$(QEMU_IMG) is required but not installed."; exit 1; }
	@command -v xorriso >/dev/null 2>&1 || { echo "xorriso is required but not installed."; exit 1; }
	@command -v $(AWK) >/dev/null 2>&1 || { echo "$(AWK) is required but not installed."; exit 1; }


.PHONY: prepare-dirs 
prepare-dirs:
	@echo "Checking and creating necessary directories..."
	@mkdir -p $(DIRECTORIES)

.PHONY: download-cloud-image
download-cloud-image:
	@echo "Preparing to download Ubuntu $(UBUNTU_VERSION) cloud image..."
	@mkdir -p "$(VM_DIR)"
	@if [ ! -f "$(BASE_IMAGE)" ]; then \
		echo "Downloading latest $(UBUNTU_VERSION) cloud image to $(VM_DIR)..."; \
		$(CURL) "$(BASE_IMAGE)" "$(IMAGE_URL_BASE)/$(IMAGE_NAME)" || { echo "Download failed"; exit 1; }; \
		$(QEMU_IMG) resize "$(BASE_IMAGE)" +18G; \
		echo "Download completed: $(BASE_IMAGE)"; \
	else \
		echo "Image already exists: $(BASE_IMAGE)"; \
	fi

.PHONY: snapshot
snapshot:
	@rm -f $(SNAPSHOT_IMAGE) &&	echo "Old snapshot deleted."
	@echo "Creating snapshot $(SNAPSHOT_IMAGE) based on $(BASE_IMAGE) ..."
	$(QEMU_IMG) create -f qcow2 -b $(abspath $(BASE_IMAGE)) -F qcow2 "$(SNAPSHOT_IMAGE)" || { echo "Snapshot create failed"; exit 1; }
	@echo "Snapshot $(SNAPSHOT_IMAGE_NAME) created in $(VM_DIR)"

.PHONY: stopvm
stopvm:
	@if [ -f "./$(PROJECT_NAME)_run" ]; then \
		if  "./$(PROJECT_NAME)_run" status | grep -q "running"  ; then \
			"./$(PROJECT_NAME)_run" stop; \
			echo "VM has stopped" ;\
		fi
			echo "VM is not running"; \
	fi

.PHONY: revert
revert: stopvm clean_rook_disks clean_temp_files snapshot makeiso create_rook_disks make-launcher
	#@echo "Reverting to original image..."

.PHONY: clean_rook_disks
clean_rook_disks:
	@echo "Cleaning rook disks"
	@rm -f $(IMAGES)

.PHONY: clean_temp_files
clean_temp_files:
	@echo "Deleting $(USER_DATA_MERGET)"
	@rm -f $(USER_DATA_MERGET)
	@echo "Deleting $(TEMP_FILE)"
	@rm -f $(TEMP_FILE)

.PHONY: clean
clean: stopvm clean_temp_files
	@echo "Cleaning ..."
	@rm -rf $(VM_DIR)
	@echo "$(VM_DIR) has been cleaned"
	@rm -f $(CLOUD_INIT_ISO)
	@echo "$(CLOUD_INIT_ISO) has been deleted"
	@rm -f $(USER_DATA)
	@echo "$(USER_DATA) has been deleted"
	@rm -f $(PROJECT_NAME)_run
	@echo "$(PROJECT_NAME)_run has been deleted"
	@rm -f ./yq
	@echo "yq has beed deleted"

.PHONY: makeiso
makeiso:
	@echo "Making cloud-init iso"
	@if [  -f "$(GRAFANA_YAML)" ]; then \
		echo "$(GRAFANA_YAML) was found, replacing $(GRAFANA_CONTENT) with content  $(GRAFANA_YAML) and creating $(USER_DATA)"; \
		$(AWK) '/$(GRAFANA_CONTENT)/ { system("cat $(GRAFANA_YAML)"); next } { print }' $(USER_DATA_YAML) > $(USER_DATA_MERGET); \
	else \
		echo "$(GRAFANA_YAML) was not found. Copy $(USER_DATA_YAML) to $(USER_DATA)"; \
		cp $(USER_DATA_YAML) $(USER_DATA_MERGET); \
	fi 
	@mv $(USER_DATA_MERGET) $(USER_DATA) || { echo "Failed to move merged user data"; exit 1; }
	@xorriso -as mkisofs -output $(CLOUD_INIT_ISO) -volid cidata -joliet -rock $(CLOUD_INIT_DIR)user-data $(CLOUD_INIT_DIR)meta-data  || { echo "Failed to make iso file"; exit 1; }
	@echo "$(CLOUD_INIT_ISO) has been created"

.PHONY: create_rook_disks
create_rook_disks: 
	@if ls $(IMAGES) >/dev/null 2>&1; then $(MAKE) clean_rook_disks; fi
	@echo "Creating disk images for Rook-Ceph"
	$(MAKE) -j4 $(IMAGES)

%.qcow2: 
	@$(QEMU_IMG) create -f $(IMG_FORMAT) $@ $($(*F)_SIZE)

.PHONY: make-launcher 
make-launcher:  
	@$(file >$(PROJECT_NAME)_run, $(launcher)) 
	@chmod +x $(PROJECT_NAME)_run
	@echo "$(PROJECT_NAME)_run has ben created"

.PHONY: install_yq
install_yq:
	@wget https://github.com/mikefarah/yq/releases/download/v4.30.6/yq_linux_amd64 -O ./yq
	@chmod +x ./yq


.PHONY: prepare-vm
prepare-vm: check-tools install_yq prepare-dirs download-cloud-image makeiso snapshot create_rook_disks make-launcher 

.PHONY: help
help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Available targets:"
	@echo "  prepare-vm           - Prepare the VM environment with all necessary steps."
	@echo "  download-cloud-image - Download the Ubuntu cloud image from the official source."
	@echo "  snapshot             - Take a snapshot of the VM image for backup or restoration."
	@echo "  revert               - Revert the VM to its original state by restoring a snapshot."
	@echo "  clean                - Clean up generated files, including VM disks and cloud-init ISO."
	@echo "  makeiso              - Create the cloud-init ISO for VM configuration."
	@echo "  create-rook-disks    - Create disk images for Rook-Ceph storage."
	@echo "  help                 - Show this help menu."
