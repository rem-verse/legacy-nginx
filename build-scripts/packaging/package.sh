#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd "$SCRIPT_DIR/../../"
export LEGACY_NGINX_DIR=$(pwd)
cd "$SCRIPT_DIR"

if [ ! -f "${LEGACY_NGINX_DIR}/build/nginx/1.21.6/nginx-1.21.6/objs/nginx" ]; then
  echo "[+] Building NGINX 1.21.6 for packaging..."
  export NGINX_VERSION="1.21.6"
  export OPENSSL_VERSION="1.0.2u"
  "${LEGACY_NGINX_DIR}"/build-scripts/building/nginx.sh
fi

nfpm package -p deb
nfpm package -p rpm
nfpm package -p apk
nfpm package -p archlinux
