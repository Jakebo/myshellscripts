#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage:"
    echo "    pullfilefromch3uu0003.sh <file name>"
    exit 1
fi

scp 199.63.152.191:/home/jakebo/$1 .
