#!/bin/bash
set -e
echo "Setting up Helm and dependencies..."
sudo -i -u user bash -c "pip3 install openshift kubernetes"
sudo -i -u user bash -c "ansible-galaxy collection install kubernetes.core"
sudo -i -u user bash -c "curl -fsSL -o /home/user/get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3"
sudo -i -u user bash -c "chmod 770 /home/user/get_helm.sh && /home/user/get_helm.sh"
echo -n "Waiting for Helm installation to complete..."
until helm version &> /dev/null; do
  echo "."
  sleep 1
done
echo "Helm is installed and ready!"

# Update Ansible and install Helm charts
sudo -i -u user pip install --upgrade ansible
sudo -i -u user ansible-galaxy collection install community.grafana
sudo -i -u user helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
sudo -i -u user helm repo add bitnami https://charts.bitnami.com/bitnami
sudo -i -u user helm repo add grafana https://grafana.github.io/helm-charts
sudo -i -u user helm repo add rook-release https://charts.rook.io/release
sudo -i -u user helm repo update