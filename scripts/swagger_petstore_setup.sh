#!/bin/bash
set -e
echo "Setting up Swagger Petstore..."
sudo -i -u user helm upgrade --install swagger-petstore oci://ghcr.io/securecodebox/helm/swagger-petstore --namespace petstore --create-namespace
sudo -i -u user kubectl -n petstore wait --for=condition=available deployment/swagger-petstore --timeout=120s
sudo -i -u user kubectl patch deployment swagger-petstore -n petstore --patch-file /mnt/files/petstore_values.yaml
sudo -i -u user kubectl patch service swagger-petstore -n petstore --patch-file /mnt/files/petstore_service_patch.yaml
sudo -i -u user kubectl rollout restart deployment/swagger-petstore -n petstore
echo "Swagger Petstore setup completed."