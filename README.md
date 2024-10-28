
# VM Preparation and Management with Makefile

This project leverages a Makefile to manage the lifecycle of a virtual machine (VM) with various utilities, such as
cloud-init and Rook-Ceph disk management, to streamline setup, configuration, and cleanup tasks.

## Prerequisites
Ensure you have the following tools installed:
- `curl`
- `qemu-img`
- `xorriso`
- `awk`
- `yq`

## Configuration

Configuration options are available in a YAML file (`config.yml`) located in the root directory. Customize this file with the necessary variables to tailor the VM setup to your specifications.

### Key Configuration Options in `config.yml`

- **project_name**: The name for your project, which also determines the name of the generated executable script (`<project_name>_run`). Run this script to start and manage the VM after setup.
- **cpus**: The number of CPUs allocated to the VM. Default is `2`.
- **ram**: The amount of RAM allocated to the VM, default is `4G`.
- **disksize**: The size of each disk created for Rook-Ceph, default is `200G`.

Example `config.yml`:
```yaml
project_name: "k3s_cluster"
cpus: 4
ram: 8G
disksize: 100G
```

## Makefile Variables

- `UBUNTU_VERSION`: Sets the Ubuntu version to download, default is `jammy`.
- `CONFIG_FILE`: Path to the configuration YAML file.
- `VM_DIR`: Directory to store VM files, default is `./vm/`.

## Usage
### Commands
Run the following commands to set up and manage your VM.

- `make prepare-vm` - Set up the VM environment, downloading images, creating disks, and generating the cloud-init ISO.
- `make download-cloud-image` - Download the specified Ubuntu cloud image.
- `make snapshot` - Create a snapshot of the current VM state for later restoration.
- `make revert` - Revert the VM to its original state by restoring from a snapshot.
- `make clean` - Clean up all generated files, VM disks, and cloud-init ISO.
- `make makeiso` - Generate a cloud-init ISO for VM configuration.
- `make create_rook_disks` - Create disk images specifically for Rook-Ceph storage.

### Running the VM

After running `make prepare-vm`, an executable script is generated in the project root with the name `<project_name>_run`. This script serves as the main way to manage the VM. Use it to start, stop, and check the VM's status:

```bash
./<project_name>_run start   # Start the VM
./<project_name>_run stop    # Stop the VM
./<project_name>_run status  # Check the VM status
```

### Default Setup

By default, this project sets up a **K3s cluster** with **Rook-Ceph** for storage, along with **Prometheus** and **Grafana** for monitoring. These services provide a lightweight Kubernetes environment, persistent storage, and monitoring capabilities out of the box.

### Help
- Run `make help` to view a list of all available targets with descriptions.

## Project Structure

- **Makefile**: Contains all commands and targets for VM management.
- **config.yml**: YAML configuration file for custom settings.
- **cloud-init/**: Directory containing cloud-init configuration files like `user-data` and `meta-data`.
- **vm/**: Default directory where VM images and snapshots will be stored.

---
