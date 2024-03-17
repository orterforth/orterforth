#!/usr/bin/env sh

set -eu

# check-memory.sh

# validates that the binary fits between ORG and ORIGIN

ORG=$(($1))
ORIGIN=$(($2))
LENGTH=$3

if [ $(( $ORG + $LENGTH )) -gt $(( $ORIGIN )) ]; then
    printf "  \033[1;31mORG=%04X ORIGIN=%04X LENGTH=%04X\033[0;0m\n" $ORG $ORIGIN $LENGTH
    printf "  \033[1;31mcode overlaps with ORIGIN\033[0;0m\n"
    exit 1
else
    printf "  \033[1;32mORG=%04X ORIGIN=%04X LENGTH=%04X\033[0;0m\n" $ORG $ORIGIN $LENGTH
fi
