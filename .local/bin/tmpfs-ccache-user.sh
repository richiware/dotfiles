#!/bin/bash

# Load config variables
. /etc/tmpfs-ccache

export CCACHE_DIR=$TMPFS

ccache -F 0 -M $SIZE &> /dev/null
