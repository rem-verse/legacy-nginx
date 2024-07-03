#!/usr/bin/env bash

set -eo pipefail

if [[ "x$NGINX_VERSION" == "x" ]]; then
  export NGINX_VERSION="1.27.0"
fi
if [[ "x$OPENSSL_VERSION" == "x" ]]; then
  export OPENSSL_VERSION="1.0.2u"
fi

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd "$SCRIPT_DIR/../../"
export LEGACY_NGINX_DIR=$(pwd)

die() {
  echo "ERROR: $1" >&2
  shift
  while [[ -n $1 ]]; do
    echo " $1" >&2
    shift
  done
  exit 1
}

if ! hash curl >/dev/null 2>&1 ; then
  die "Please install the \`curl\` tool in order to fetch the nginx packages"
fi
if ! hash make >/dev/null 2>&1 ; then
  die "Please install the \`make\` tool in order to build the nginx packages"
fi

if [[ ! -f "./build/openssl/${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}/apps/openssl" ]]; then
  echo "[+] Ensuring OpenSSL is built..."
  ./build-scripts/building/openssl.sh
fi

mkdir -p "build/nginx/${NGINX_VERSION}"
cd "build/nginx/${NGINX_VERSION}"
echo "[+] Fetching NGINX Version [$NGINX_VERSION]..."
curl -sSL -O "https://legacy-nginx-ci.archive.rem-verse.com/mirror/nginx/${NGINX_VERSION}/nginx.tar.gz"
echo "[+] Unpacking NGINX..."
tar xvzf nginx.tar.gz
cd "nginx-${NGINX_VERSION}"
echo "[+] Building NGINX..."
./configure --with-pcre --with-http_ssl_module --with-http_v2_module --with-stream=dynamic --with-http_addition_module --with-http_mp4_module --with-stream_ssl_module --with-stream_ssl_preread_module --with-openssl="${LEGACY_NGINX_DIR}/build/openssl/${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}" --with-openssl-opt="enable-ssl2 enable-ssl3 shared zlib"
if ! hash nproc >/dev/null 2>&1 ; then
  export CORE_COUNT=$(nproc --all)
else
  export CORE_COUNT=1
fi
make -j "$CORE_COUNT"
echo "[+] Built NGINX!"
