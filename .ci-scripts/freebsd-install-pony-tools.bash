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

curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/ponylang/ponyup/latest-release/ponyup-init.sh | sh

export PATH="$HOME/.local/share/ponyup/bin/:$PATH"

ponyup update ponyc "${1}"

