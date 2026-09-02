#!/usr/bin/env bash

set -euo pipefail

GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=

cleanup() {
  unset GRAFANA_ADMIN_USER GRAFANA_ADMIN_PASSWORD
}
trap cleanup EXIT

read -rsp "Grafana admin password: " GRAFANA_ADMIN_PASSWORD
printf '\n'

if [[ -z "${GRAFANA_ADMIN_PASSWORD}" ]]; then
  echo "Password must not be empty." >&2
  exit 1
fi

kubectl create namespace monitoring --dry-run=client -o yaml \
  | kubectl apply -f -

kubectl create secret generic grafana-admin \
  --namespace monitoring \
  --from-literal=admin-user="${GRAFANA_ADMIN_USER}" \
  --from-literal=admin-password="${GRAFANA_ADMIN_PASSWORD}" \
  --dry-run=client \
  -o yaml \
  | kubectl apply -f -

echo "Secret grafana-admin is configured in namespace monitoring."
