#!/bin/bash

set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update

apt-get install -y \
  ca-certificates \
  curl \
  git \
  unzip \
  jq \
  docker.io

systemctl enable docker
systemctl start docker

usermod -aG docker ubuntu