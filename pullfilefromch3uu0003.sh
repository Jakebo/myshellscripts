#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage:"
    echo "    pullfilefromch3uu0003.sh <file name>"
    exit 1
fi

scp ch3uu0003.honeywell.com:/home/jakebo/$1 .
