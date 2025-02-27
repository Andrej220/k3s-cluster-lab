#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
if [[ -f "$SCRIPT_DIR/config.env.sh" ]]; then
    source "$SCRIPT_DIR/config.env.sh"
else
    echo "Error: config.env.sh not found in $SCRIPT_DIR"
    exit 1
fi

echo "Validating Tekton release manifest..."
DRY_RUN=$(kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml --dry-run=client 2>&1)
if [[ $? -ne 0 ]]; then
    echo "Error: Tekton release manifest validation failed"
    echo "Dry run output:"
    echo "$DRY_RUN"
    exit 1
fi

echo "Applying Tekton release manifest..."
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
echo "Waiting for Tektone deployment to be available..."
kubectl wait --for=condition=available --timeout=300s deployment/tekton-pipelines-controller -n tekton-pipelines


mkdir -p /tmp/ssh
chmod 700 /tmp/ssh
rm -f /tmp/ssh/github*

echo "Generating SSH key..."
ssh-keygen -t rsa -b 4096 -f /tmp/ssh/github -N '' -C "tekton-pipeline-key"

chmod 600 /tmp/ssh/github
chmod 644 /tmp/ssh/github.pub

if [[ ! -f /tmp/ssh/github || ! -f /tmp/ssh/github.pub ]]; then
    echo "Error: SSH key files not found in /tmp/ssh/"
    exit 1
fi
echo "Validating of SSH secrets..."
kubectl create secret generic git-ssh-key \
    --from-file=ssh-privatekey=/tmp/ssh/github \
    --from-file=ssh-publickey=/tmp/ssh/github.pub \
    --type=kubernetes.io/ssh-auth --dry-run=client -o yaml 2>&1
if [[ $? -ne 0 ]]; then
    echo "Error: Creating SSH secret validation failed"
    echo "Dry run output:"
    exit 1
fi
echo "Creating Kubernetes secret for SSH keys..."
kubectl create secret generic git-ssh-key \
            --from-file=ssh-privatekey=/tmp/ssh/github  \
            --from-file=ssh-publickey=/tmp/ssh/github.pub \
            --type=kubernetes.io/ssh-auth

if [[ ! -f "$MANIFESTS_DIR/local-registry.yaml" ]]; then
    echo "Error: $MANIFESTS_DIR/local-registry.yaml not found"
    exit 1
fi
echo "Applying local registry manifest..."
kubectl apply -f "$MANIFESTS_DIR"/local-registry.yaml

if [[ $? -ne 0 ]]; then
    echo "Error: Applying local registry failed"
    exit 1
fi

if ! curl -s -L -o /dev/null -w "%{http_code}" -I "$TEKTON_APPLICATION_IMG" | grep -q "2.."; then
    echo "Pipeline application repo is not reachable"
    exit 1
fi
git clone "$TEKTONE_APPLICATION_IMG"

cd "$TEKTON_DIR"  || { 
    cecho "Failed to change directory to $TEKTON_DIR"
    exit 1
    }

./apply.sh || {
    echo "Failed to start pipeline"
    exit 1
}

echo "Tekton installation completed successfully!"


