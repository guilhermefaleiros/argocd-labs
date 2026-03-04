#!/usr/bin/env bash

set -euo pipefail

ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"

argocd admin initial-password -n "${ARGOCD_NAMESPACE}"
