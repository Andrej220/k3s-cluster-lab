#!/bin/bash
set -e
echo "Running Ansible playbooks to deploy K3S, Rook-Ceph, Grafana"
sudo -i -u user ansible-playbook -i /mnt/files/ansible/inventory/hosts.ini /mnt/files/ansible/k3s_lab_setup_new.yaml
sudo -i -u user ansible-playbook -i /mnt/files/ansible/inventory/hosts.ini /mnt/files/ansible/rook_ceph_install_new.yaml
echo "Ansible deployments completed."