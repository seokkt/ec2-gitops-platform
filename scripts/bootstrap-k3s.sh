#!/usr/bin/env bash

set -euo pipefail

K3S_CONFIG=/etc/rancher/k3s/k3s.yaml
UBUNTU_HOME="$(getent passwd ubuntu | cut -d: -f6)"
KUBECONFIG_LINE='export KUBECONFIG=$HOME/.kube/config'

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

UBUNTU_UID="$(id -u ubuntu)"
UBUNTU_GID="$(id -g ubuntu)"
UBUNTU_KUBECONFIG="${UBUNTU_HOME}/.kube/config"
UBUNTU_BASHRC="${UBUNTU_HOME}/.bashrc"

sudo install -d -m 0700 -o "${UBUNTU_UID}" -g "${UBUNTU_GID}" "${UBUNTU_HOME}/.kube"
sudo install -m 0600 -o "${UBUNTU_UID}" -g "${UBUNTU_GID}" "${K3S_CONFIG}" "${UBUNTU_KUBECONFIG}"

sudo -u ubuntu touch "${UBUNTU_BASHRC}"
if ! sudo -u ubuntu grep -Fqx "${KUBECONFIG_LINE}" "${UBUNTU_BASHRC}"; then
  printf '\n%s\n' "${KUBECONFIG_LINE}" | sudo tee -a "${UBUNTU_BASHRC}" >/dev/null
fi

export KUBECONFIG="${UBUNTU_KUBECONFIG}"
sudo -u ubuntu env HOME="${UBUNTU_HOME}" KUBECONFIG="${KUBECONFIG}" kubectl get nodes
sudo -u ubuntu env HOME="${UBUNTU_HOME}" KUBECONFIG="${KUBECONFIG}" kubectl get pods -A
