#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd "$SCRIPT_DIR/../../"
export LEGACY_NGINX_DIR=$(pwd)
cd "$SCRIPT_DIR"

if [ ! -f "${LEGACY_NGINX_DIR}/build/nginx/1.29.0/nginx-1.29.0/objs/nginx" ]; then
  echo "[+] Building NGINX 1.29.0 for packaging..."
  export NGINX_VERSION="1.29.0"
  export OPENSSL_VERSION="1.0.2u"
  "${LEGACY_NGINX_DIR}"/build-scripts/building/nginx.sh
fi

if [ "$(dpkg --print-architecture)" = "amd64" ]; then
  echo "Building AMD64 packages..."
  nfpm package --config nfpm-amd64.yaml -p deb
  nfpm package --config nfpm-amd64.yaml -p rpm
  nfpm package --config nfpm-amd64.yaml -p apk
  nfpm package --config nfpm-amd64.yaml -p archlinux
else
  echo "Building ARM64 packages..."
  nfpm package --config nfpm-arm64.yaml -p deb
  nfpm package --config nfpm-arm64.yaml -p rpm
  nfpm package --config nfpm-arm64.yaml -p apk
  nfpm package --config nfpm-arm64.yaml -p archlinux
fi
