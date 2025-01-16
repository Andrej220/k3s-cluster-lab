#!/bin/bash
set -e

SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
source "$SCRIPT_DIR"/config.env.sh

echo "Setting up Swagger Petstore..."
helm upgrade --install swagger-petstore oci://ghcr.io/securecodebox/helm/swagger-petstore --namespace petstore --create-namespace
kubectl -n petstore wait --for=condition=available deployment/swagger-petstore --timeout=120s
kubectl patch deployment swagger-petstore -n petstore --patch-file "$FILES_DIR"/petstore_values.yaml
kubectl patch service swagger-petstore -n petstore --patch-file "$FILES_DIR"/petstore_service_patch.yaml
kubectl rollout restart deployment/swagger-petstore -n petstore
echo "Swagger Petstore setup completed."