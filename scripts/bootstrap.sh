#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER_CONFIG="${CLUSTER_CONFIG:-${ROOT_DIR}/cluster/kind.yaml}"
KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-kind}"

if kind get clusters | grep -qx "${KIND_CLUSTER_NAME}"; then
  echo "Cluster ${KIND_CLUSTER_NAME} already exists. Reusing it."
else
  kind create cluster --name "${KIND_CLUSTER_NAME}" --config "${CLUSTER_CONFIG}"
fi

sh "${ROOT_DIR}/scripts/install-argocd.sh"
sh "${ROOT_DIR}/scripts/install-rollouts.sh"

kubectl wait --for=condition=Available deployment --all -n argocd --timeout=300s
kubectl wait --for=condition=Available deployment --all -n argo-rollouts --timeout=300s

cat <<'EOF'
Bootstrap completed.

Next steps:
1. kubectl port-forward svc/argocd-server -n argocd 8080:443
2. sh scripts/get-argocd-password.sh
3. kubectl apply -f bootstrap/root-application.yaml
EOF
