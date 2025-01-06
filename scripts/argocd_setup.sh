#!/bin/bash

echo "Creating namespace argocd"
sudo -i -u user kubectl apply -f /mnt/files/manifests/argocd_namespace.yaml

echo "Installing ArgoCD"
sudo -i -u user kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Install loadbalancer"
sudo -i -u user kubectl apply -f /mnt/files/manifests/argocd-loadbalancer.yaml