#!/bin/bash
set -e

SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
source "$SCRIPT_DIR"/config.env.sh

echo "Setting up Promtail..."
helm upgrade --install promtail grafana/promtail -n monitoring -f "$FILES_DIR"/promtail_values.yaml
kubectl apply -f "$FILES_DIR"/promtail_svc.yaml
echo "Promtail setup completed."