#!/usr/bin/env sh

set -eu

print_info() {
    printf '* \033[1;33m%s\033[0;0m\n' "$1"
}

# start machine emulator
print_info 'Starting machine'
sh scripts/start.sh /dev/stdin /dev/stdout machine.pid $@

# wait for completed DR1 file
while ! [ -f "${HEXFILE}" ]; do sleep 1; done

# stop machine emulator
print_info 'Stopping machine'
sh scripts/stop.sh machine.pid
