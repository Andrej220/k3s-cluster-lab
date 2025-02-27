#!/bin/bash
set -e

SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
source "$SCRIPT_DIR"/config.env.sh

echo "Running Ansible playbooks to deploy K3S, Rook-Ceph, Grafana"
sudo -i -u user ansible-playbook -i /mnt/files/ansible/inventory/hosts.ini "$ANSIBLE_DIR"/k3s_lab_setup_new.yaml
#sudo -i -u user ansible-playbook -i /mnt/files/ansible/inventory/hosts.ini /mnt/files/ansible/rook_ceph_install_new.yaml
echo "Ansible deployments completed."