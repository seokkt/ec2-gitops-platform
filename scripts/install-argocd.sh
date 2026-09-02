#!/usr/bin/env bash

set -euo pipefail

ARGOCD_MANIFEST_URL=https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f "${ARGOCD_MANIFEST_URL}"

kubectl rollout status deployment --all -n argocd --timeout=300s
kubectl wait --for=condition=Ready pod --all -n argocd --timeout=300s
kubectl get pods -n argocd
