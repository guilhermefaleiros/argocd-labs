#!/usr/bin/env bash

set -euo pipefail

ROLLOUTS_NAMESPACE="${ROLLOUTS_NAMESPACE:-argo-rollouts}"
ROLLOUTS_INSTALL_URL="${ROLLOUTS_INSTALL_URL:-https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml}"

kubectl create namespace "${ROLLOUTS_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n "${ROLLOUTS_NAMESPACE}" -f "${ROLLOUTS_INSTALL_URL}"
