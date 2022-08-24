#!/usr/bin/env sh

set -eu

# stop.sh

# stop a process, remove pidfile

# get args
PIDFILE="$1"

# stop existing processes in pidfile
kill -9 $(cat $PIDFILE) || true

# remove pidfile
rm -f $PIDFILE || true
