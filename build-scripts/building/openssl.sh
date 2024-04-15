#!/usr/bin/env bash

set -eo pipefail

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
  die "Please install the \`curl\` tool in order to fetch the openssl packages"
fi
if ! hash make >/dev/null 2>&1 ; then
  die "Please install the \`make\` tool in order to build the openssl packages"
fi

mkdir -p "build/openssl/${OPENSSL_VERSION}"
cd "build/openssl/${OPENSSL_VERSION}"
echo "[+] Fetching OpenSSL Version [$OPENSSL_VERSION]..."
curl -sSL -O "https://legacy-nginx-ci.archive.rem-verse.com/mirror/openssl/${OPENSSL_VERSION}/openssl.tar.gz"
tar xvzf openssl.tar.gz
cd "openssl-${OPENSSL_VERSION}"
./config enable-ssl2 enable-ssl3 shared zlib
if ! hash nproc >/dev/null 2>&1 ; then
  export CORE_COUNT=$(nproc --all)
else
  export CORE_COUNT=1
fi
make -j "$CORE_COUNT"