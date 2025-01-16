#!/bin/bash
set -e
echo "Running final verification checks..."
kubectl get pods --all-namespaces
kubectl get namespaces
echo "Final verification completed."