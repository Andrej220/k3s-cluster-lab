#!/bin/bash

echo "Creating namespace argocd"
sudo -i -u user kubectl apply -f /mnt/files/manifests/argocd_namespace.yaml

echo "Installing ArgoCD"
sudo -i -u user kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Installing loadbalancer"
sudo -i -u user kubectl apply -f /mnt/files/manifests/argocd-loadbalancer.yaml

echo "Installing ArgoCD CLI"
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

echo "Deploy applications"
sudo -i -u user bash /mnt/scripts/argocd_installapps.sh