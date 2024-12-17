#!/bin/bash
set -e

echo ""

echo "Installing Grafana"
sudo -i -u user kubectl apply -f /mnt/files/manifests/grafana.yaml

echo "Installing Prometheus"
sudo -i -u user helm install prometheus prometheus-community/prometheus --namespace monitoring
sudo -i -u user helm upgrade prometheus prometheus-community/prometheus --namespace monitoring --set server.service.type=NodePort --set server.service.nodePort=30900  --set server.service.port=9090 --set server.service.targetPort=9090

echo "Installing Loki"
sudo -i -u user helm upgrade --install loki grafana/loki-distributed -n monitoring -f /mnt/files/loki_values.yaml

echo "Installing Jaeger"
sudo -i -u user helm upgrade --install jaeger bitnami/jaeger -n monitoring 

echo "Monitoring tools setup completed."