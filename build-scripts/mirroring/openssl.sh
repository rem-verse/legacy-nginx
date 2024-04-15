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

if [[ "x$1" == "x" ]] || [[ "x$2" == "x" ]]; then
  die "Please call the script with a version of OpenSSL to mirror: (e.g. \`$0 1.0.2 u\`)"
fi
OPENSSL_MAJOR_VERSION="$1"
OPENSSL_MINOR_VERSION="$2"
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

mkdir -p ./build/package-mirroring/openssl/
cd ./build/package-mirroring/openssl/

curl -sSL -o "unsafe-unvalidated-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}" "https://www.openssl.org/source/old/${OPENSSL_MAJOR_VERSION}/openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}.tar.gz"
# We don't download the hash file, as not every release has a SHA256 hash, and
# we assume the signature over TLS should be valid and trusted enough at this point.
curl -sSL -o "unsafe-unvalidated-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}.asc" "https://www.openssl.org/source/old/${OPENSSL_MAJOR_VERSION}/openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}.tar.gz.asc"

gpg:download "openssl-security.asc" "https://www.openssl.org/news/openssl-security.asc"
# Matt Caswell on OpenSSL signed important OpenSSL Builds.
gpg --recv-keys 8657ABB260F056B1E5190839D9C4D26D0E604491

if ! gpg --verify "unsafe-unvalidated-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}.asc" "unsafe-unvalidated-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}"; then
  die "Cannot validate downloaded OpenSSL binary! Not Using!"
fi
mv "unsafe-unvalidated-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}" "openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}.tar.gz"
mv "unsafe-unvalidated-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}.asc" "openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}.tar.gz.asc"

sha256sum "openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}.tar.gz" > "openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}.tar.gz.sha256"
sha256sum "openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}.tar.gz.asc" > "openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}.tar.gz.asc.sha256"
sha512sum "openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}.tar.gz" > "openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}.tar.gz.sha512"
sha512sum "openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}.tar.gz.asc" > "openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}.tar.gz.asc.sha512"
b2sum "openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}.tar.gz" > "openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}.tar.gz.b2"
b2sum "openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}.tar.gz.asc" > "openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}.tar.gz.asc.b2"

b2 upload-file "${B2_BUCKET_NAME}" "./openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}.tar.gz" "${B2_BUCKET_PREFIX:-mirror/openssl/}${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}/openssl.tar.gz"
b2 upload-file "${B2_BUCKET_NAME}" "./openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}.tar.gz.asc" "${B2_BUCKET_PREFIX:-mirror/openssl/}${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}/openssl.tar.gz.asc"
b2 upload-file "${B2_BUCKET_NAME}" "./openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}.tar.gz.sha256" "${B2_BUCKET_PREFIX:-mirror/openssl/}${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}/openssl.tar.gz.sha256"
b2 upload-file "${B2_BUCKET_NAME}" "./openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}.tar.gz.asc.sha256" "${B2_BUCKET_PREFIX:-mirror/openssl/}${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}/openssl.tar.gz.asc.sha256"
b2 upload-file "${B2_BUCKET_NAME}" "./openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}.tar.gz.sha512" "${B2_BUCKET_PREFIX:-mirror/openssl/}${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}/openssl.tar.gz.sha512"
b2 upload-file "${B2_BUCKET_NAME}" "./openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}.tar.gz.asc.sha512" "${B2_BUCKET_PREFIX:-mirror/openssl/}${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}/openssl.tar.gz.asc.sha512"
b2 upload-file "${B2_BUCKET_NAME}" "./openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}.tar.gz.b2" "${B2_BUCKET_PREFIX:-mirror/openssl/}${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}/openssl.tar.gz.b2"
b2 upload-file "${B2_BUCKET_NAME}" "./openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}.tar.gz.asc.b2" "${B2_BUCKET_PREFIX:-mirror/openssl/}${OPENSSL_MAJOR_VERSION}${OPENSSL_MINOR_VERSION}/openssl.tar.gz.asc.b2"
