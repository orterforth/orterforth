#!/usr/bin/env sh

# reset.sh

set -e

# try cold start and default memory top
printf 'C'
sleep 1
printf '\n'
sleep 1
printf '\n'
sleep 1

# we may be in Forth, so exit
printf 'MON\n'
sleep 1

# reset
printf 'reset\n'
sleep 1

# cold start and desired memory top
printf 'C'
sleep 1
printf '35071\n'
sleep 1
printf '\n'
sleep 1

# ACK
printf 'print chr$(6)\n'
sleep 1
