#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage:"
    echo "    pushfiletoch3uu0003.sh <file name>"
    exit 1
fi

scp $1 ch3uu0003.honeywell.com:/home/jakebo/
