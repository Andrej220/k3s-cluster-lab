# Kubernetes Cluster Setup with Rook-Ceph, Grafana, and Prometheus

This project automates the deployment of a lightweight Kubernetes cluster (k3s) within a virtual machine (VM). The cluster is pre-configured with:

- **Rook-Ceph**: A storage orchestrator for managing Ceph clusters within Kubernetes.
- **Grafana**: An open-source platform for monitoring and observability.
- **Prometheus**: A systems monitoring and alerting toolkit.

By using this project, you can quickly set up a fully functional Kubernetes environment suitable for testing, development, or learning purposes.

## Table of Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Configuration](#configuration)
  - [Configuration Parameters](#configuration-parameters)
- [Usage](#usage)
  - [Available Makefile Targets](#available-makefile-targets)
  - [Steps to Prepare and Run the VM](#steps-to-prepare-and-run-the-vm)
    - [1. Prepare the VM Environment](#1-prepare-the-vm-environment)
    - [2. Launch the VM](#2-launch-the-vm)
    - [3. Access the Kubernetes Cluster](#3-access-the-kubernetes-cluster)
  - [Customizing cloud-init Configuration](#customizing-cloud-init-configuration)
  - [Cleaning Up](#cleaning-up)
- [Notes](#notes)
- [License](#license)

## Introduction

This project leverages `make` and QEMU to automate the setup of a VM running a k3s Kubernetes cluster. The cluster is configured with:

- **Rook-Ceph** for storage orchestration and management.
- **Grafana** and **Prometheus** for monitoring the cluster and workloads.

The automation includes:

- Downloading and configuring an Ubuntu cloud image.
- Setting up cloud-init for VM customization.
- Installing and configuring k3s, Rook-Ceph, Grafana, and Prometheus.
- Preparing additional disk images for Rook-Ceph storage pools.
- Generating scripts to manage the VM lifecycle.

## Prerequisites

Ensure you have the following installed:

- **Make**: To run the `Makefile` commands.
- **QEMU**: For creating and managing virtual machine images (`qemu-img`, `qemu-system`).
- **curl**: To download the Ubuntu cloud image.
- **xorriso**: To create ISO images for cloud-init.
- **bash**: For executing shell scripts.
- **Ansible**: For provisioning the VM with k3s, Rook-Ceph, Grafana, and Prometheus.
- **An internet connection**: Required to download the Ubuntu cloud image and software packages.

Ensure you have permissions to create and modify files in the project directory.

## Configuration

The project uses a `config.yml` file for configuration parameters. This file should be placed in the root directory of the project.

Example `config.yml`:

```yaml
project_name: "k3s-cluster"
vm_dir: "./vm/"
hostport: "8022"
vmport: "22"
cpus: "2"
ram: "4096"
disksize: "50G"
```
