#!/bin/bash
set -e

SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
source "$SCRIPT_DIR"/config.env.sh

echo "Setting up Promtail..."
sudo -i -u user helm upgrade --install promtail grafana/promtail -n monitoring -f "$FILES_DIR"/promtail_values.yaml
sudo -i -u user kubectl apply -f "$FILES_DIR"/promtail_svc.yaml
echo "Promtail setup completed."