#!/usr/bin/env bash

set -euo pipefail

K3S_CONFIG=/etc/rancher/k3s/k3s.yaml
UBUNTU_HOME="$(getent passwd ubuntu | cut -d: -f6)"

if [[ -z "${UBUNTU_HOME}" ]]; then
  echo "The ubuntu user does not exist." >&2
  exit 1
fi

if command -v k3s >/dev/null 2>&1 && sudo systemctl is-active --quiet k3s; then
  echo "k3s is already installed and running; skipping installation."
else
  curl -sfL https://get.k3s.io | sudo sh -
fi

sudo systemctl enable k3s
sudo systemctl is-active --quiet k3s
sudo systemctl --no-pager status k3s

sudo install -d -m 0700 -o ubuntu -g ubuntu "${UBUNTU_HOME}/.kube"
sudo install -m 0600 -o ubuntu -g ubuntu "${K3S_CONFIG}" "${UBUNTU_HOME}/.kube/config"

sudo -u ubuntu env KUBECONFIG="${UBUNTU_HOME}/.kube/config" kubectl get nodes
sudo -u ubuntu env KUBECONFIG="${UBUNTU_HOME}/.kube/config" kubectl get pods -A
