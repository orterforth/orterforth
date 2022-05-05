#!/usr/bin/env bash

set -eu

# tcp-redirect.sh

# wait for TCP conn and get a fd
while ! exec 3<>"/dev/tcp/$1/$2" ; do
  sleep 1
done >/dev/null 2>&1

# get command and args
shift
shift

# redirect it to the TCP fd
$@ <&3 1>&3
