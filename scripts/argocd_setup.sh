#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
source "$SCRIPT_DIR"/config.env.sh

echo "Creating namespace argocd"
sudo -i -u user kubectl apply -f "$ARGOCD_NAMESPACE_MANIFEST"


echo "Installing ArgoCD"
sudo -i -u user kubectl apply -n argocd -f "$ARGOCD_INSTALL_URL"

echo "Waiting for ArgoCD to reach Ready state..."
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-application-controller -n argocd --timeout=300s

echo "Installing loadbalancer"
sudo -i -u user kubectl apply -f "$ARGOCD_LOADBALANCER_MANIFEST"

echo "Installing ArgoCD CLI"
curl -sSL -o argocd-linux-amd64 "$ARGOCD_CLI_URL"
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

echo "Adding secrets"
sudo -i -u user kubectl apply -f "$ARGOCD_SECRET"

echo "Deploy applications"
sudo -i -u user "$SCRIPTS_DIR"/argocd_installapps.sh
