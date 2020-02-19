#!/bin/bash

# Load config variables
. /etc/tmpfs-ccache

export CCACHE_DIR=$TMPFS
export CCACHE_CONFIGPATH=~/.ccache/ccache.conf

ccache -F 0 -M $SIZE &> /dev/null
