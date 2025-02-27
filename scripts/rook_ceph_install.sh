#!/bin/bash

set -e  

SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
source "$SCRIPT_DIR"/config.env.sh

echo "Installing Rook-Ceph operator..."
helm install --create-namespace --namespace rook-ceph rook-ceph rook-release/rook-ceph -f "$FILES_DIR"/rook_values.yaml

echo "Waiting for Rook-Ceph operator to be ready..."
kubectl wait --namespace rook-ceph --for=condition=ready pod -l app=rook-ceph-operator --timeout=300s

echo "Installing Rook-Ceph cluster..."
kubectl apply -f "$FILES_DIR"/ceph_cluster.yaml

echo "Applying block pool configuration..."
kubectl apply -f "$FILES_DIR"/blockpool.yaml

echo "Applying storage class configuration..."
kubectl apply -f "$FILES_DIR"/storageclass.yaml

echo "Waiting for CephCluster to reach Ready state..."
kubectl wait --namespace rook-ceph --for=condition=ready cephcluster rook-ceph --timeout=600s

echo "Deploying toolbox..."
kubectl apply -f "$FILES_DIR"/toolbox.yaml

echo "Waiting for toolbox pod to be ready..."
kubectl wait --namespace rook-ceph --for=condition=ready pod -l app=rook-ceph-tools --timeout=300s

echo "All steps completed successfully."


