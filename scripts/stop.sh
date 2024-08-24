#!/usr/bin/env sh

set -eu

# stop.sh

# stop a process, remove pidfile

# get args
PIDFILE="$1"

if [ -f "$PIDFILE" ]; then
  # SIGTERM
  kill $(cat "$PIDFILE") 2> /dev/null || true
  if ps -p $(cat "$PIDFILE") > /dev/null
  then
    # SIGKILL
    sleep 1
    kill -9 $(cat "$PIDFILE") 2> /dev/null || true
  fi

  # remove pidfile
  rm "$PIDFILE" || true
fi
