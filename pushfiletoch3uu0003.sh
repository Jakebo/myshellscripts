#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage:"
    echo "    pushfiletoch3uu0003.sh <file name>"
    exit 1
fi

for f in $@; do
    scp $f ch3uu0003.honeywell.com:/home/jakebo/
done
