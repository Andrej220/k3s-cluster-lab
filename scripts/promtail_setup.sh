#!/bin/bash
set -e
echo "Setting up Promtail..."
sudo -i -u user helm upgrade --install promtail grafana/promtail -n monitoring -f /mnt/files/promtail_values.yaml
sudo -i -u user kubectl apply -f /mnt/files/promtail_svc.yaml
echo "Promtail setup completed."