.ONESHELL:

.PHONY: default
default: prepare-vm


TARGETS := snapshot stopvm clean_temp_files clean makeiso make-launcher prepare-vm
$(foreach target,$(TARGETS),$(eval $(target): read_config))

UBUNTU_VERSION ?= jammy
IMAGE_URL_BASE = https://cloud-images.ubuntu.com/$(UBUNTU_VERSION)/current
IMAGE_NAME := $(UBUNTU_VERSION)-server-cloudimg-amd64.img
YAML_PARSER := ./yq
CONFIG_FILE := ./config.yml
VMRUN_SCRIPT :=./vm-runner/vmrun
CLOUD_INIT_DIR := ./cloud-init/
AWK := awk
CURL := curl -L -o
QEMU_IMG := qemu-img
IMG_FORMAT = qcow2
# TO BE REPLACED Grafana.yaml
GRAFANA_CONTENT := \#GRAFANA_CONTENT
define LAUNCHER
#!/bin/bash 
$(VMRUN_SCRIPT) -c ./config.yml $$1 
endef

check_yq:
	@if [ ! -x "./yq" ]; then \
		echo "yq not found, installing..."; \
		$(MAKE) install_yq; \
	fi

.PHONY: read_config
read_config: check_yq
	@echo "Reading configuration from $(CONFIG_FILE)"
	$(eval PROJECT_NAME := $(shell ./yq -e ".project_name" config.yml || echo "k3"))
	$(eval VM_DIR := $(shell ./yq -e ".vm_dir" config.yml || echo "./vm/"))

	$(eval PROJECT_DIR := $(CURDIR))
	$(eval BASE_IMAGE := $(VM_DIR)/$(PROJECT_NAME).qcow2)
	$(eval SNAPSHOT_IMAGE := $(VM_DIR)$(PROJECT_NAME)_snapshot.qcow2)
	$(eval SNAPSHOT_IMAGE_NAME := $(PROJECT_NAME)_snapshot.qcow2)
	$(eval CLOUD_INIT_ISO := $(CLOUD_INIT_DIR)cloud-init.iso )
	$(eval USER_DATA := $(CLOUD_INIT_DIR)user-data )
	$(eval USER_DATA_YAML := $(CLOUD_INIT_DIR)user-data.yaml )
	$(eval USER_DATA_MERGED := $(CLOUD_INIT_DIR)user-data-merged.yaml)
	$(eval GRAFANA_YAML := $(CLOUD_INIT_DIR)grafana.yaml)
	$(eval CPUS := $(shell ./yq -e ".cpus" config.yml || echo "2"))
	$(eval RAM := $(shell ./yq -e ".ram" config.yml || echo "4G"))
	$(eval DISK_SIZE := $(shell ./yq -e ".disksize" config.yml || echo "200G"))
	$(eval IMAGES := \
    	$(VM_DIR)disk1.qcow2 \
    	$(VM_DIR)disk2.qcow2 \
    	$(VM_DIR)disk3.qcow2 \
		$(VM_DIR)disk4.qcow2 )
	#$(eval disk1_SIZE := $(DISK_SIZE))
	#$(eval disk2_SIZE := $(DISK_SIZE))
	#$(eval disk3_SIZE := $(DISK_SIZE))
	#$(eval disk4_SIZE := $(DISK_SIZE))
	$(eval DIRECTORIES := $(VM_DIR) $(CLOUD_INIT_DIR) )

.PHONY: check-tools
check-tools:
	@command -v $(CURL) >/dev/null 2>&1 || { echo "$(CURL) is required but not installed."; exit 1; }
	@command -v $(QEMU_IMG) >/dev/null 2>&1 || { echo "$(QEMU_IMG) is required but not installed."; exit 1; }
	@command -v xorriso >/dev/null 2>&1 || { echo "xorriso is required but not installed."; exit 1; }
	@command -v $(AWK) >/dev/null 2>&1 || { echo "$(AWK) is required but not installed."; exit 1; }


.PHONY: prepare-dirs 
prepare-dirs: read_config
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
	@echo "Deleting $(USER_DATA_MERGED)"
	@rm -f $(USER_DATA_MERGED)
	#@echo "Deleting $(TEMP_FILE)"
	#@rm -f $(TEMP_FILE)

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
		$(AWK) '/$(GRAFANA_CONTENT)/ { system("cat $(GRAFANA_YAML)"); next } { print }' $(USER_DATA_YAML) > $(USER_DATA_MERGED); \
	else \
		echo "$(GRAFANA_YAML) was not found. Copy $(USER_DATA_YAML) to $(USER_DATA)"; \
		cp $(USER_DATA_YAML) $(USER_DATA_MERGED); \
	fi 
	@mv $(USER_DATA_MERGED) $(USER_DATA) || { echo "Failed to move merged user data"; exit 1; }
	@xorriso -as mkisofs -output $(CLOUD_INIT_ISO) -volid cidata -joliet -rock $(CLOUD_INIT_DIR)user-data $(CLOUD_INIT_DIR)meta-data  || { echo "Failed to make iso file"; exit 1; }
	@echo "$(CLOUD_INIT_ISO) has been created"

.PHONY: create_rook_disks
create_rook_disks: 
	@if ls $(IMAGES) >/dev/null 2>&1; then $(MAKE) clean_rook_disks; fi
	@echo "Creating disk images for Rook-Ceph"
	$(MAKE) -j4 $(IMAGES) DISK_SIZE=$(DISK_SIZE)

%.qcow2: 
	$(QEMU_IMG) create -f $(IMG_FORMAT) $@ $(DISK_SIZE)

.PHONY: make-launcher 
make-launcher:  
	@$(file >$(PROJECT_NAME)_run, $(LAUNCHER)) 
	@chmod +x $(PROJECT_NAME)_run
	@echo "$(PROJECT_NAME)_run has ben created"

.PHONY: install_yq
install_yq:
	@wget https://github.com/mikefarah/yq/releases/download/v4.30.6/yq_linux_amd64 -O ./yq
	@chmod +x ./yq


.PHONY: prepare-vm
prepare-vm: check-tools prepare-dirs download-cloud-image makeiso snapshot create_rook_disks make-launcher 

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
