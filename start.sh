#!/bin/bash
set -ex

git clone -b 4.1 https://github.com/aondio/libvmod-bodyaccess.git ./libvmod-bodyaccess && \
cd libvmod-bodyaccess && \
./autogen.sh && \
./configure && \
make install && \
service nginx start && \
service varnish start && \
nodejs ../src/server.js && \
varnishlog | grep "\[VARNISH\]"
