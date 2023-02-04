#!/usr/bin/env sh

set -eu

# check-memory.sh

# validates that the binary fits between ORG and ORIGIN

ORG=$(($1))
ORIGIN=$(($2))
LENGTH=$3

echo "ORG=$ORG ORIGIN=$ORIGIN LENGTH=$LENGTH"

if [ $(( $ORG + $LENGTH )) -gt $(( $ORIGIN )) ]; then
    echo "code overlaps with ORIGIN"
    exit 1
fi
