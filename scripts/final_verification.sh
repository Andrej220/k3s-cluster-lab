#!/bin/bash
set -e
echo "Running final verification checks..."
sudo -i -u user kubectl get pods --all-namespaces
sudo -i -u user kubectl get namespaces
echo "Final verification completed."