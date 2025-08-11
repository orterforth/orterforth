#!/usr/bin/env sh

set -eu

print_info() {
    printf '* \033[1;33m%s\033[0;0m\n' "$1"
}

# start with an empty file
print_info 'Clearing DR1'
rm -f ${HEXFILE}
printf '' > ${HEXFILE}.io

# start disc
print_info 'Starting disc'
sh scripts/start.sh /dev/stdin /dev/stdout disc.pid ${SYSTEM}/disc $@ model.img ${HEXFILE}.io

# wait until saved
print_info 'Waiting until saved'
sh scripts/wait-until-saved.sh ${HEXFILE}.io

# stop disc
print_info 'Stopping disc'
sh scripts/stop.sh disc.pid

# complete saved DR1 file
mv ${HEXFILE}.io ${HEXFILE}
