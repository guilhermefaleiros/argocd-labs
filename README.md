# ArgoCD Labs

Hands-on lab repository for studying GitOps with Argo CD and progressive delivery strategies with Argo Rollouts on a local `kind` cluster.

The included scenarios are:

- `basic`: traditional deployment synchronized by Argo CD
- `canary`: canary rollout with Argo Rollouts
- `bluegreen`: blue/green rollout with active and preview services

## Purpose

This repository demonstrates, in a practical way, how to:

- create a local cluster for testing
- install Argo CD and Argo Rollouts
- bootstrap applications from Git
- compare a standard deployment, canary, and blue/green rollout

## Structure

```text
.
├── apps/
│   ├── basic/
│   │   └── manifests/
│   │       └── deployment.yaml
│   ├── bluegreen/
│   │   └── manifests/
│   │       └── rollout.yaml
│   └── canary/
│       └── manifests/
│           └── rollout.yaml
├── bootstrap/
│   ├── applications/
│   │   ├── basic.yaml
│   │   ├── bluegreen.yaml
│   │   └── canary.yaml
│   └── root-application.yaml
├── cluster/
│   └── kind.yaml
├── scripts/
│   ├── bootstrap.sh
│   ├── get-argocd-password.sh
│   ├── install-argocd.sh
│   └── install-rollouts.sh
└── README.md
```

## What Changed in the Organization

The repository now separates responsibilities more clearly:

- `apps/`: Kubernetes manifests and Rollouts for each scenario
- `bootstrap/`: Argo CD `Application` resources
- `cluster/`: local cluster configuration
- `scripts/`: installation and bootstrap automation

The repository also now uses `yaml` consistently, and the `Application` manifests point to `targetRevision: main` instead of `HEAD`.

## Prerequisites

Install these binaries first:

- `docker`
- `kind`
- `kubectl`
- `argocd`

Optional, but recommended for observing rollouts:

- `kubectl-argo-rollouts`

## Quick Start

### 1. Bring Everything Up at Once

```bash
sh scripts/bootstrap.sh
```

This script:

- creates the `kind` cluster using [cluster/kind.yaml](/Users/guilhermefaleirosdesiqueira/studies/argocd-labs/cluster/kind.yaml)
- installs Argo CD
- installs Argo Rollouts
- waits for the main deployments to become available

### 2. Open the Argo CD UI

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

In another terminal:

```bash
sh scripts/get-argocd-password.sh
```

Access:

- URL: `https://localhost:8080`
- username: `admin`

### 3. Register the Labs in Argo CD

You can register everything at once using the app-of-apps pattern:

```bash
kubectl apply -f bootstrap/root-application.yaml
```

Or register each scenario individually:

```bash
kubectl apply -f bootstrap/applications/basic.yaml
kubectl apply -f bootstrap/applications/canary.yaml
kubectl apply -f bootstrap/applications/bluegreen.yaml
```

## Scenarios

### `basic`

Applies the resources from [apps/basic/manifests/deployment.yaml](/Users/guilhermefaleirosdesiqueira/studies/argocd-labs/apps/basic/manifests/deployment.yaml) into the `basic` namespace.

Created resources:

- `Deployment`
- `Service`

Verification:

```bash
kubectl get all -n basic
```

### `canary`

Applies the resources from [apps/canary/manifests/rollout.yaml](/Users/guilhermefaleirosdesiqueira/studies/argocd-labs/apps/canary/manifests/rollout.yaml) into the `canary` namespace.

Configured strategy:

- 25%
- pause
- 50%
- pause
- 100%

Verification:

```bash
kubectl get all -n canary
kubectl argo rollouts get rollout canary -n canary --watch
```

### `bluegreen`

Applies the resources from [apps/bluegreen/manifests/rollout.yaml](/Users/guilhermefaleirosdesiqueira/studies/argocd-labs/apps/bluegreen/manifests/rollout.yaml) into the `bluegreen` namespace.

Configured strategy:

- active service for production traffic
- preview service for validation
- manual promotion

Verification:

```bash
kubectl get all -n bluegreen
kubectl argo rollouts get rollout bluegreen -n bluegreen --watch
kubectl argo rollouts promote bluegreen -n bluegreen
```

## App of Apps

The manifest [bootstrap/root-application.yaml](/Users/guilhermefaleirosdesiqueira/studies/argocd-labs/bootstrap/root-application.yaml) registers the three child `Application` resources at [bootstrap/applications/basic.yaml](/Users/guilhermefaleirosdesiqueira/studies/argocd-labs/bootstrap/applications/basic.yaml), [bootstrap/applications/canary.yaml](/Users/guilhermefaleirosdesiqueira/studies/argocd-labs/bootstrap/applications/canary.yaml), and [bootstrap/applications/bluegreen.yaml](/Users/guilhermefaleirosdesiqueira/studies/argocd-labs/bootstrap/applications/bluegreen.yaml) in one step.

This is the closest flow in this repository to a real GitOps bootstrap.

## How to Test Changes

Make changes in the manifests under `apps/`, for example:

- change the `kubedevio/web-color` image
- adjust the replica count
- change canary weights and pauses
- change blue/green promotion behavior

Then:

1. commit and push
2. wait for Argo CD to reconcile
3. follow the result in the UI or with `kubectl`

## Useful Commands

List applications:

```bash
kubectl get applications -n argocd
```

List scenario resources:

```bash
kubectl get all -n basic
kubectl get all -n canary
kubectl get all -n bluegreen
```

List rollouts:

```bash
kubectl get rollout -n canary
kubectl get rollout -n bluegreen
```

## About Versions

The install scripts support overriding the source URL through environment variables:

- `ARGOCD_INSTALL_URL`
- `ROLLOUTS_INSTALL_URL`

Example:

```bash
ARGOCD_INSTALL_URL="https://raw.githubusercontent.com/argoproj/argo-cd/<version>/manifests/install.yaml" \
sh scripts/install-argocd.sh
```

This makes it possible to pin versions without editing the scripts.

## Cleanup

```bash
kind delete cluster
```
