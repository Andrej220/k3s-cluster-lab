#!/bin/bash
set -e


SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
source "$SCRIPT_DIR"/config.env.sh

echo "Installing Grafana"
echo "Installing namespace - monitoring"
kubectl apply -f "$MANIFESTS_DIR"/monitoring_namespace.yaml
echo "Installing Config map"
kubectl apply -f "$MANIFESTS_DIR"/grafana_datasources_configmap.yaml
echo "Deploing grafana"
kubectl apply -f "$MANIFESTS_DIR"/grafana_deployment.yaml
kubectl rollout status deployment/grafana -n monitoring

echo "Installing Prometheus"
helm install prometheus prometheus-community/prometheus --namespace monitoring --wait --timeout 300s
helm upgrade prometheus prometheus-community/prometheus --namespace monitoring -f "$MANIFESTS_DIR"/prometheus_values.yaml --wait --timeout 300s

echo "Installing Loki"
helm upgrade --install loki grafana/loki-distributed -n monitoring -f "$FILES_DIR"/loki_values.yaml --wait --timeout 300s

echo "Installing Jaeger"
helm upgrade --install jaeger bitnami/jaeger -n monitoring  --wait --timeout 300s

echo "Installing Open Telemetry==========================================="
helm repo list
helm search repo open-telemetry
helm install otel-collector-cluster open-telemetry/opentelemetry-collector --values "$MANIFESTS_DIR"/otel_values.yaml
echo "Monitoring tools setup completed."