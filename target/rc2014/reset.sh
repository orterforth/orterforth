#!/usr/bin/env sh

# reset.sh

# This script attempts to exit any program, reset the machine 
# and set Memory Top appropriately

set -e

# try cold start and default memory top
printf 'C'
sleep 1
printf '\r'
sleep 1
printf '\r'
sleep 1

# we may be in Forth, so exit to Basic
printf 'MON\r'
sleep 1

# reset
printf 'reset\r'
sleep 1

# cold start and desired memory top
printf 'C'
sleep 1
printf '35071\r'
sleep 1
printf '\r'
sleep 1

# send ACK back, then the client will exit
printf 'print chr$(6)\r'
sleep 1
