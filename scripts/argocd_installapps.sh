#!/bin/bash

ARGOSRV="localhost:8443"
ARGOUSR="admin"
ARGOPWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
argocd login --username $ARGOUSR --password $ARGOPWD $ARGOSRV --insecure

argocd app create my-nginx-app \
  --repo https://github.com/Andrej220/nginx.git \
  --path . \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace nginx \
  --sync-option CreateNamespace=true \
  --sync-policy automated

