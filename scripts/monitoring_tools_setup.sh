#!/bin/bash
set -e


SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
source "$SCRIPT_DIR"/config.env.sh

echo "Installing Grafana"
echo "Installing namespace - monitoring"
sudo -i -u user kubectl apply -f "$MANIFESTS_DIR"/monitoring_namespace.yaml
echo "Installing Config map"
sudo -i -u user kubectl apply -f "$MANIFESTS_DIR"/grafana_datasources_configmap.yaml
echo "Deploing grafana"
sudo -i -u user kubectl apply -f "$MANIFESTS_DIR"/grafana_deployment.yaml
kubectl rollout status deployment/grafana -n monitoring

echo "Installing Prometheus"
sudo -i -u user helm install prometheus prometheus-community/prometheus --namespace monitoring --wait --timeout 300s
sudo -i -u user helm upgrade prometheus prometheus-community/prometheus --namespace monitoring --set server.service.type=NodePort --set server.service.nodePort=30900  --set server.service.port=9090 --set server.service.targetPort=9090 --wait --timeout 300s

echo "Installing Loki"
sudo -i -u user helm upgrade --install loki grafana/loki-distributed -n monitoring -f "$FILES_DIR"/loki_values.yaml --wait --timeout 300s

echo "Installing Jaeger"
sudo -i -u user helm upgrade --install jaeger bitnami/jaeger -n monitoring  --wait --timeout 300s

echo "Monitoring tools setup completed."