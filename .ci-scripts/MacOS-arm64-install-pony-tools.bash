#!/bin/bash

case "${1}" in
"release")
  ;;
"nightly")
  ;;
*)
  echo "invalid ponyc version"
  echo "Options:"
  echo "release"
  echo "nightly"
  exit 1
esac

pushd /tmp || exit
mkdir ponyc
curl https://dl.cloudsmith.io/public/ponylang/nightlies/raw/versions/latest/ponyc-arm64-apple-darwin.tar.gz --output ponyc.tar.gz
tar xzf ponyc.tar.gz -C ponyc --strip-components=1
popd || exit
