#!/bin/bash

#
# Libressl is required by ponyup
#

# get the latest version of libressl
brew update
brew install libressl

#
# Install ponyup
#

curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/ponylang/ponyup/latest-release/ponyup-init.sh | sh

export PATH="$HOME/.local/share/ponyup/bin/:$PATH"

ponyup update ponyc nightly
