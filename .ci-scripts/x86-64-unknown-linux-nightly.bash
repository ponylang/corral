#!/bin/bash

set -e

API_KEY=$1
if [[ ${API_KEY} == "" ]]
then
  echo "API_KEY needs to be supplied as first script argument."
  exit 1
fi

TODAY=$(date +%Y%m%d)

# Compiler target parameters
ARCH=x86-64

# Triple construction
VENDOR=unknown
OS=linux
TRIPLE=${ARCH}-${VENDOR}-${OS}

# Build parameters
BUILD_PREFIX=$(mktemp -d)
CORRAL_VERSION="nightly-${TODAY}"
BUILD_DIR=${BUILD_PREFIX}/${CORRAL_VERSION}

# Asset information
PACKAGE_DIR=$(mktemp -d)
PACKAGE=corral-${TRIPLE}

# Cloudsmith configuration
CLOUDSMITH_VERSION=${TODAY}
ASSET_OWNER=ponylang
ASSET_REPO=nightlies
ASSET_PATH=${ASSET_OWNER}/${ASSET_REPO}
ASSET_FILE=${PACKAGE_DIR}/${PACKAGE}.tar.gz
ASSET_SUMMARY="Pony dependency manager"
ASSET_DESCRIPTION="https://github.com/ponylang/corral"

# Build corral installation
echo "Building corral..."
make install prefix=${BUILD_DIR} arch=${ARCH} version="${CORRAL_VERSION}" \
  static=true linker=bfd

# Package it all up
echo "Creating .tar.gz of corral..."
pushd ${BUILD_PREFIX} || exit 1
tar -cvzf ${ASSET_FILE} *
popd || exit 1

# Ship it off to cloudsmith
echo "Uploading package to cloudsmith..."
cloudsmith push raw --version "${CLOUDSMITH_VERSION}" --api-key ${API_KEY} \
  --summary "${ASSET_SUMMARY}" --description "${ASSET_DESCRIPTION}" \
  ${ASSET_PATH} ${ASSET_FILE}

