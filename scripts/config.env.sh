
# User and Paths
USER_NAME="user"
HOME_DIR="/home/$USER_NAME"
SCRIPTS_DIR="/mnt/scripts"
FILES_DIR="/mnt/files"
MANIFESTS_DIR="$FILES_DIR/manifests"
ANSIBLE_DIR="$FILES_DIR/ansible"
ARGOSRV="localhost:8443"
ARGOUSR="admin"
ARGOPWD="adminadmin"

# URLs
HELM_INSTALL_URL="https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3"
ARGOCD_INSTALL_URL="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
ARGOCD_CLI_URL="https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"

# Kubernetes Namespaces
MONITORING_NAMESPACE="monitoring"
ROOK_CEPH_NAMESPACE="rook-ceph"
PETSTORE_NAMESPACE="petstore"
ARGOCD_NAMESPACE="argocd"

# Helm Chart Repositories
PROMETHEUS_REPO="https://prometheus-community.github.io/helm-charts"
BITNAMI_REPO="https://charts.bitnami.com/bitnami"
GRAFANA_REPO="https://grafana.github.io/helm-charts"
ROOK_REPO="https://charts.rook.io/release"

# File Paths
ARGOCD_NAMESPACE_MANIFEST="$MANIFESTS_DIR/argocd_namespace.yaml"
ARGOCD_LOADBALANCER_MANIFEST="$MANIFESTS_DIR/argocd-loadbalancer.yaml"
ROOK_VALUES_FILE="$FILES_DIR/rook_values.yaml"
CEPH_CLUSTER_MANIFEST="$FILES_DIR/ceph_cluster.yaml"
BLOCKPOOL_MANIFEST="$FILES_DIR/blockpool.yaml"
STORAGECLASS_MANIFEST="$FILES_DIR/storageclass.yaml"
TOOLBOX_MANIFEST="$FILES_DIR/toolbox.yaml"
PETSTORE_VALUES_PATCH="$FILES_DIR/petstore_values.yaml"
PROMTAIL_VALUES="$FILES_DIR/promtail_values.yaml"
ARGOCD_SECRET="$MANIFESTS_DIR"/argocd_secrets.yaml


check_dirs() {
    local dirs=("$@")
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            echo "Error: Directory $dir does not exist or is not a directory"
            exit 1
        fi
        if [[ ! -r "$dir" ]]; then
            echo "Error: Directory $dir is not readable"
            exit 1
        fi
    done
}

check_dirs "$SCRIPTS_DIR" "$FILES_DIR" "$MANIFESTS_DIR" "$HOME_DIR"
