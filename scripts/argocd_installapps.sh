#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
if [[ -f "$SCRIPT_DIR/config.env.sh" ]]; then
    source "$SCRIPT_DIR/config.env.sh"
else
    echo "Error: config.env.sh not found in $SCRIPT_DIR"
    exit 1
fi

ARGODEFPWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
ARGOPWD=$(kubectl -n argocd get secret argocd-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "Checking ArgoCD CLI"
command -v argocd > /dev/null || { echo "argocd CLI not found! Install it first."; exit 1; }

echo "Login to ArgoCD"
argocd login --username $ARGOUSR --password $ARGODEFPWD $ARGOSRV --insecure

echo "Updating password..."
argocd account update-password --current-password "$ARGODEFPWD" --new-password "$ARGOPWD" > /dev/null
echo "Password updated successfully!"

echo "Verifying new password..."
argocd logout "$ARGOSRV" > /dev/null
argocd login "$ARGOSRV" \
  --username "$ARGOUSR" \
  --password "$ARGOPWD" \
  --insecure > /dev/null
echo "Password change verified successfully!"

echo "Install ArgoCD applications"
echo "Install Nginx"
kubectl apply -f "$MANIFESTS_DIR"/argocd_applications.yaml 
# argocd app create nginx-app \
#   --repo https://github.com/Andrej220/nginx.git \
#   --path . \
#   --dest-server https://kubernetes.default.svc \
#   --dest-namespace nginx \
#   --sync-option CreateNamespace=true \
#   --sync-policy automated
