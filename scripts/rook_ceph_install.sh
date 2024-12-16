#!/bin/bash

set -e  

echo "Installing Rook-Ceph operator..."
sudo -i -u user helm install --create-namespace --namespace rook-ceph rook-ceph rook-release/rook-ceph -f /mnt/files/rook_values.yaml

echo "Waiting for Rook-Ceph operator to be ready..."
kubectl wait --namespace rook-ceph --for=condition=ready pod -l app=rook-ceph-operator --timeout=300s

echo "Installing Rook-Ceph cluster..."
sudo -i -u user kubectl apply -f /mnt/files/ceph_cluster.yaml

echo "Applying block pool configuration..."
sudo -i -u user kubectl apply -f /mnt/files/blockpool.yaml

echo "Applying storage class configuration..."
sudo -i -u user kubectl apply -f /mnt/files/storageclass.yaml

echo "Waiting for CephCluster to reach Ready state..."
kubectl wait --namespace rook-ceph --for=condition=ready cephcluster rook-ceph --timeout=600s

echo "Deploying toolbox..."
sudo -i -u user kubectl apply -f /mnt/files/toolbox.yaml

echo "Waiting for toolbox pod to be ready..."
kubectl wait --namespace rook-ceph --for=condition=ready pod -l app=rook-ceph-tools --timeout=300s

echo "All steps completed successfully."


