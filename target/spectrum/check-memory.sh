#!/usr/bin/env sh

set -e

ORG=$(($1))
ORIGIN=$(($2))
LENGTH=$3

echo "ORG=$ORG ORIGIN=$ORIGIN LENGTH=$LENGTH"

if [ $(( $ORG + $LENGTH )) -gt $(( $ORIGIN )) ]; then
    echo "code overlaps with ORIGIN"
    exit 1
fi
