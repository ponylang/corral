#!/bin/bash

#
# Install ponyc the hard way
# It will end up in /tmp/ponyc/ with the binary at /tmp/ponyc/bin/ponyc
#

cd /tmp
mkdir ponyc
curl -O 'https://dl.cloudsmith.io/public/ponylang/nightlies/raw/versions/latest/ponyc-x86-64-unknown-freebsd-12.1.tar.gz'
tar -xvf ponyc-x86-64-unknown-freebsd-12.1.tar.gz -C ponyc --strip-components=1
