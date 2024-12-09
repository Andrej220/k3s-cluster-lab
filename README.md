
# K3s Cluster Lab

A project for automating the deployment of a Kubernetes (K3s) cluster, complete with integrated storage (Rook-Ceph) and monitoring (Prometheus & Grafana) for a hands-on DevOps learning environment.

## Table of Contents
- [About the Project](#about-the-project)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

## About the Project
K3s Cluster Lab is designed to help DevOps engineers and learners deploy a fully-functional Kubernetes cluster using K3s. This project simplifies deploying a local development environment with automated setup scripts, enabling integrated monitoring (Grafana, Prometheus) and storage (Rook-Ceph).

## Features
- Automated setup of a K3s cluster.
- Integrated storage solution using Rook-Ceph.
- Monitoring with Prometheus and Grafana.
- Lightweight and easily customizable for different environments.

## Prerequisites
- Linux-based OS
- `curl`
- `qemu-img`
- `xorriso`
- `awk`
- `yq`
- Basic familiarity with command-line tools.

## Installation
1. **Clone the repository**:
   ```bash
   git clone https://github.com/Andrej220/k3s-cluster-lab.git
   cd k3s-cluster-lab
   ```
2. **Edit Configuration**:
   Edit the `config.yml` to customize your VM settings (e.g., CPUs, memory, disk size).
3. **Run Setup**:
   ```bash
   make setup
   ```

## Usage
- To start the VM:
  ```bash
  ./<project_name>_run
  ```
- Access the K3s cluster with `kubectl` commands:
  ```bash
  export KUBECONFIG=./k3s-cluster/config
  kubectl get nodes
  ```

## Configuration
- **project_name**: Sets the project name. It affects the generated VM names and script filenames.
- **cpus**: Number of CPUs allocated to the VM.
- **memory**: Amount of RAM for the VM.
- **disk_size**: Size of the VM's disk.
- **network**: Network configuration settings.

## Troubleshooting
- **Problem**: Unable to connect to Grafana.
  **Solution**: Ensure port forwarding is set up correctly using `kubectl port-forward`.
- **Problem**: Rook-Ceph isn't creating pools.
  **Solution**: Verify that the correct storage class is set up and the cluster has sufficient resources.

## Contributing
Contributions are welcome! Please fork the repository, create a new branch, and open a pull request.

## License
Distributed under the MIT License. See `LICENSE` for more information.

## Contact
Andrey Zargarov - [LinkedIn](https://www.linkedin.com/in/andrey-zargarov/) 