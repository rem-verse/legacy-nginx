#!/usr/bin/env bash

set -eo pipefail

die() {
  echo "ERROR: $1" >&2
  shift
  while [[ -n $1 ]]; do
    echo " $1" >&2
    shift
  done
  exit 1
}

gpg:download() {
  local -r filename="$1"
  local -r url="$2"

  curl -sSL -o "$filename" "$url"
  gpg_key_id=$(gpg --show-keys "$filename"  | head -n 2 | tail -n 1 | tr -d ' ')
  if ! gpg --list-sigs "$gpg_key_id" >/dev/null 2>&1 ; then
    gpg --import "$filename"
  fi
}

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd "$SCRIPT_DIR/../../"
export LEGACY_NGINX_DIR=$(pwd)

if [[ "x$1" == "x" ]]; then
  die "Please call the script with a version of NGINX to mirror: (e.g. \`$0 1.25.4\`)"
fi
NGINX_VERSION="$1"
if ! hash b2 >/dev/null 2>&1 ; then
  die "Please install the Backblaze CLI in order to mirror versioned assets"
fi
if ! hash sha256sum >/dev/null 2>&1 ; then
  die "Please install the \`sha256sum\` tool in order to mirror versioned assets"
fi
if ! hash sha512sum >/dev/null 2>&1 ; then
  die "Please install the \`sha512sum\` tool in order to mirror versioned assets"
fi
if ! hash b2sum >/dev/null 2>&1 ; then
  die "Please install the \`b2sum\` tool in order to mirror versioned assets"
fi
if ! hash curl >/dev/null 2>&1 ; then
  die "Please install the \`curl\` tool in order to mirror versioned assets"
fi

if [[ "x$B2_BUCKET_NAME" == "x" ]] || [[ "x$B2_APPLICATION_KEY_ID" == "x" ]] || [[ "x$B2_APPLICATION_KEY" == "x" ]]; then
  die \
    "Backblaze Upload Configuration is not set, so unsure how to mirror a package." \
    "Environment Variables that need to be set, and their current values:" \
    "B2_BUCKET_NAME = ${B2_BUCKET_NAME}" \
    "B2_APPLICATION_KEY_ID = ${B2_APPLICATION_KEY_ID}" \
    "B2_APPLICATION_KEY = ${B2_APPLICATION_KEY}"
fi

mkdir -p ./build/package-mirroring/nginx/
cd ./build/package-mirroring/nginx/
curl -sSL -o "unsafe-unvalidated-${NGINX_VERSION}" "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"
curl -sSL -o "unsafe-unvalidated-${NGINX_VERSION}.asc" "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz.asc"

gpg:download "nginx_signing.key" "https://nginx.org/keys/nginx_signing.key"
gpg:download "maxim.key" "https://nginx.org/keys/maxim.key"
gpg:download "pluknet.key" "https://nginx.org/keys/pluknet.key"
gpg:download "sb.key" "https://nginx.org/keys/sb.key"
gpg:download "thresh.key" "https://nginx.org/keys/thresh.key"
# For some older versions we know about.
gpg:download "mdounin.key" "https://cdn.archive.rem-verse.com/sdk-extras/old-nginx-keys/mdounin.key"

if ! gpg --verify "unsafe-unvalidated-${NGINX_VERSION}.asc" "unsafe-unvalidated-${NGINX_VERSION}"; then
  die "Cannot validate downloaded nginx binary! Not using!"
fi
mv "unsafe-unvalidated-${NGINX_VERSION}" "nginx-${NGINX_VERSION}.tar.gz"
mv "unsafe-unvalidated-${NGINX_VERSION}.asc" "nginx-${NGINX_VERSION}.tar.gz.asc"

sha256sum "nginx-${NGINX_VERSION}.tar.gz" > "nginx-${NGINX_VERSION}.tar.gz.sha256"
sha256sum "nginx-${NGINX_VERSION}.tar.gz.asc" > "nginx-${NGINX_VERSION}.tar.gz.asc.sha256"
sha512sum "nginx-${NGINX_VERSION}.tar.gz" > "nginx-${NGINX_VERSION}.tar.gz.sha512"
sha512sum "nginx-${NGINX_VERSION}.tar.gz.asc" > "nginx-${NGINX_VERSION}.tar.gz.asc.sha512"
b2sum "nginx-${NGINX_VERSION}.tar.gz" > "nginx-${NGINX_VERSION}.tar.gz.b2"
b2sum "nginx-${NGINX_VERSION}.tar.gz.asc" > "nginx-${NGINX_VERSION}.tar.gz.asc.b2"

b2 upload-file "${B2_BUCKET_NAME}" "./nginx-${NGINX_VERSION}.tar.gz" "${B2_BUCKET_PREFIX:-mirror/nginx/}${NGINX_VERSION}/nginx.tar.gz"
b2 upload-file "${B2_BUCKET_NAME}" "./nginx-${NGINX_VERSION}.tar.gz.asc" "${B2_BUCKET_PREFIX:-mirror/nginx/}${NGINX_VERSION}/nginx.tar.gz.asc"
b2 upload-file "${B2_BUCKET_NAME}" "./nginx-${NGINX_VERSION}.tar.gz.sha256" "${B2_BUCKET_PREFIX:-mirror/nginx/}${NGINX_VERSION}/nginx.tar.gz.sha256"
b2 upload-file "${B2_BUCKET_NAME}" "./nginx-${NGINX_VERSION}.tar.gz.asc.sha256" "${B2_BUCKET_PREFIX:-mirror/nginx/}${NGINX_VERSION}/nginx.tar.gz.asc.sha256"
b2 upload-file "${B2_BUCKET_NAME}" "./nginx-${NGINX_VERSION}.tar.gz.sha512" "${B2_BUCKET_PREFIX:-mirror/nginx/}${NGINX_VERSION}/nginx.tar.gz.sha512"
b2 upload-file "${B2_BUCKET_NAME}" "./nginx-${NGINX_VERSION}.tar.gz.asc.sha512" "${B2_BUCKET_PREFIX:-mirror/nginx/}${NGINX_VERSION}/nginx.tar.gz.asc.sha512"
b2 upload-file "${B2_BUCKET_NAME}" "./nginx-${NGINX_VERSION}.tar.gz.b2" "${B2_BUCKET_PREFIX:-mirror/nginx/}${NGINX_VERSION}/nginx.tar.gz.b2"
b2 upload-file "${B2_BUCKET_NAME}" "./nginx-${NGINX_VERSION}.tar.gz.asc.b2" "${B2_BUCKET_PREFIX:-mirror/nginx/}${NGINX_VERSION}/nginx.tar.gz.asc.b2"
