#!/usr/bin/env sh

set -eu

# stop.sh

# stop a process, remove pidfile

# get args
PIDFILE="$1"

if [ -f "$PIDFILE" ]; then
  # stop existing processes in pidfile
  kill $(cat "$PIDFILE") 2> /dev/null || true
  sleep 1
  kill -9 $(cat "$PIDFILE") 2> /dev/null || true

  # remove pidfile
  rm "$PIDFILE" || true
fi
